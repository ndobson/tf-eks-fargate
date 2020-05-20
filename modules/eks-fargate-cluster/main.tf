###
# EKS Cluster
###

data "aws_eks_cluster_auth" "aws_iam_authenticator" {
  name = module.eks_cluster.eks_cluster_id
}

# Create an EKS cluster with no nodegroups or Fargate profiles
module "eks_cluster" {
    source                = "git::https://github.com/cloudposse/terraform-aws-eks-cluster.git?ref=tags/0.22.0"
    namespace             = var.namespace
    stage                 = var.stage
    name                  = var.name
    attributes            = var.attributes
    tags                  = var.tags
    region                = var.region
    vpc_id                = var.vpc_id
    subnet_ids            = var.cluster_subnet_ids
    kubernetes_version    = var.kubernetes_version
    oidc_provider_enabled = var.oidc_provider_enabled
    endpoint_private_access = true
    map_additional_aws_accounts = var.map_additional_aws_accounts
    map_additional_iam_roles = var.map_additional_iam_roles
    map_additional_iam_users = var.map_additional_iam_users
}

# Create Fargate profile for default and kube-system namespace
module "eks_fargate_profile_default" {
    source               = "../eks-fargate-profile"
    namespace            = var.namespace
    stage                = var.stage
    name                 = "default"
    attributes           = var.attributes
    tags                 = var.tags
    subnet_ids           = var.profile_subnet_ids
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
  depends_on = [module.eks_fargate_profile_default]
}

resource "null_resource" "coredns_restart" {
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<EOF
kubectl --kubeconfig=<(echo '${data.template_file.kubeconfig.rendered}') \
  rollout restart -n kube-system deployment coredns
EOF
  }
  depends_on = [null_resource.coredns_patch]
}

provider "kubernetes" {
  alias = "eks"
  host                   = module.eks_cluster.eks_cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks_cluster.eks_cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.aws_iam_authenticator.token
  load_config_file       = false
}

# Deploy ALB ingress controller
module "alb_ingress_controller" {
  providers = {
    kubernetes = kubernetes.eks
  }
  source  = "iplabs/alb-ingress-controller/kubernetes"
  version = "3.1.0"

  k8s_cluster_type = "eks"
  k8s_namespace    = "kube-system"

  k8s_cluster_name = module.eks_cluster.eks_cluster_id
  aws_tags = merge(var.tags, map("FargateProfile", module.eks_fargate_profile_default.eks_fargate_profile_id))
}

module "external-dns" {
  providers = {
    kubernetes = kubernetes.eks
  }
  source = "../external-dns"

  eks_cluster_name = module.eks_cluster.eks_cluster_id
  tags = merge(var.tags, map("FargateProfile", module.eks_fargate_profile_default.eks_fargate_profile_id))
  owner_id = var.private_hosted_zone_id
}