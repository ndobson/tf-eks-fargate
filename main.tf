provider "aws" {
  region = var.region
}

provider "kubernetes" {
  alias = "eks"
  host                   = module.eks_cluster.eks_cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks_cluster.eks_cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.aws_iam_authenticator.token
  load_config_file       = false
}

provider "k8s" {
  host                   = module.eks_cluster.eks_cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks_cluster.eks_cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.aws_iam_authenticator.token
  load_config_file       = false
}

data "aws_eks_cluster_auth" "aws_iam_authenticator" {
  name = module.eks_cluster.eks_cluster_id
}

module "label" {
    source     = "git::https://github.com/cloudposse/terraform-null-label.git?ref=tags/0.16.0"
    namespace  = var.namespace
    name       = var.name
    stage      = var.stage
    delimiter  = var.delimiter
    attributes = compact(concat(var.attributes, list("cluster")))
    tags       = var.tags
}

locals {
    tags = merge(module.label.tags, map("kubernetes.io/cluster/${module.label.id}", "shared"))
}

###
# Base Infrastructure
###

# Create a VPC for the EKS cluster
module "vpc" {
    source     = "git::https://github.com/cloudposse/terraform-aws-vpc.git?ref=tags/0.10.0"
    namespace  = var.namespace
    stage      = var.stage
    name       = var.name
    attributes = var.attributes
    cidr_block = var.vpc_cidr_block
    tags       = local.tags
}

# Associate a second cidr range to the VPC for the Fargate pod subnets
resource "aws_vpc_ipv4_cidr_block_association" "secondary_cidr" {
    vpc_id     = module.vpc.vpc_id
    cidr_block = var.vpc_secondary_cidr_block
}

# Create subnets in the primary cidr range across all availability zones
module "public_subnets" {
    source              = "git::https://github.com/cloudposse/terraform-aws-multi-az-subnets.git?ref=tags/0.4.0"
    namespace           = var.namespace
    stage               = var.stage
    name                = var.name
    availability_zones  = var.availability_zones
    vpc_id              = module.vpc.vpc_id
    cidr_block          = var.vpc_cidr_block
    type                = "public"
    igw_id              = module.vpc.igw_id
    nat_gateway_enabled = "true"
    tags                = merge(local.tags, map("kubernetes.io/role/internal-elb", "1"))
}

# Create subnets in the secondary cidr range across all availability zones
module "private_subnets" {
    source             = "git::https://github.com/cloudposse/terraform-aws-multi-az-subnets.git?ref=tags/0.4.0"
    namespace          = var.namespace
    stage              = var.stage
    name               = var.name
    availability_zones = var.availability_zones
    vpc_id             = module.vpc.vpc_id
    cidr_block         = var.vpc_secondary_cidr_block
    type               = "private"
    az_ngw_ids         = module.public_subnets.az_ngw_ids
    tags               = local.tags
    # tags               = merge(local.tags, map("kubernetes.io/role/internal-elb", "1"))
}

###
# EKS Cluster
###

# Create an EKS cluster with no nodegroups or Fargate profiles
module "eks_cluster" {
    source                = "git::https://github.com/cloudposse/terraform-aws-eks-cluster.git?ref=tags/0.22.0"
    namespace             = var.namespace
    stage                 = var.stage
    name                  = var.name
    attributes            = var.attributes
    tags                  = var.tags
    region                = var.region
    vpc_id                = module.vpc.vpc_id
    subnet_ids            = concat(values(module.public_subnets.az_subnet_ids),values(module.private_subnets.az_subnet_ids))
    kubernetes_version    = var.kubernetes_version
    oidc_provider_enabled = var.oidc_provider_enabled
}

# Create Fargate profile for default and kube-system namespace
module "eks_fargate_profile_default" {
    source               = "./modules/eks-fargate-profile"
    namespace            = var.namespace
    stage                = var.stage
    name                 = "default"
    attributes           = var.attributes
    tags                 = var.tags
    subnet_ids           = values(module.private_subnets.az_subnet_ids)
    cluster_name         = module.eks_cluster.eks_cluster_id

    selectors = {
        default = {}
        kube-system = {}
    }
}

# TODO: This is a hacky workaround to this requirement of patching the coredns deployment, build a better solution.
# https://docs.aws.amazon.com/eks/latest/userguide/fargate-getting-started.html#fargate-gs-coredns
data "template_file" "kubeconfig" {
  template = <<EOF
apiVersion: v1
kind: Config
current-context: terraform
clusters:
- name: main
  cluster:
    certificate-authority-data: ${module.eks_cluster.eks_cluster_certificate_authority_data}
    server: ${module.eks_cluster.eks_cluster_endpoint}
contexts:
- name: terraform
  context:
    cluster: main
    user: terraform
users:
- name: terraform
  user:
    token: ${data.aws_eks_cluster_auth.aws_iam_authenticator.token}
EOF
}

resource "null_resource" "coredns_patch" {
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<EOF
kubectl --kubeconfig=<(echo '${data.template_file.kubeconfig.rendered}') \
  patch deployment coredns \
  --namespace kube-system \
  --type=json \
  -p='[{"op": "remove", "path": "/spec/template/metadata/annotations", "value": "eks.amazonaws.com/compute-type"}]'
EOF
  }
}

# Deploy ALB ingress controller
module "alb_ingress_controller" {
  source  = "iplabs/alb-ingress-controller/kubernetes"
  version = "3.1.0"

  k8s_cluster_type = "eks"
  k8s_namespace    = "kube-system"

  aws_region_name  = var.region
  k8s_cluster_name = module.eks_cluster.eks_cluster_id
}

###
# Deploy demo application
###

# Create application namespace Fargate profile
module "eks_fargate_profile_2048-game" {
    source               = "./modules/eks-fargate-profile"
    namespace            = var.namespace
    stage                = var.stage
    name                 = "2048-game"
    attributes           = var.attributes
    tags                 = var.tags
    subnet_ids           = values(module.private_subnets.az_subnet_ids)
    cluster_name         = module.eks_cluster.eks_cluster_id

    selectors = {
        "2048-game" = {}
    }
}

# TODO: Fix dependency issue between this module and ingress controller
module "k8s_2048-game" {
    source = "./modules/2048-game"
}
