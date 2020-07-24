###
# EKS Cluster
###

data "aws_eks_cluster_auth" "aws_iam_authenticator" {
  name = module.eks_cluster.eks_cluster_id
}

# Create an EKS cluster with no nodegroups or Fargate profiles
module "eks_cluster" {
  source                      = "git::https://github.com/cloudposse/terraform-aws-eks-cluster.git?ref=tags/0.22.0"
  name                        = var.name
  tags                        = var.tags
  region                      = var.region
  vpc_id                      = var.vpc_id
  subnet_ids                  = var.cluster_subnet_ids
  kubernetes_version          = var.kubernetes_version
  oidc_provider_enabled       = var.oidc_provider_enabled
  endpoint_private_access     = true
  map_additional_aws_accounts = var.map_additional_aws_accounts
  map_additional_iam_roles    = var.map_additional_iam_roles
  map_additional_iam_users    = var.map_additional_iam_users
}

module "vpc_endpoints" {
  source             = "../vpc-endpoint"
  services           = ["ecr.dkr", "ecr.api", "s3", "logs", "sts", "ec2", "elasticloadbalancing", "appmesh-envoy-management"]
  vpc_id             = var.vpc_id
  name               = var.name
  subnet_ids         = var.local_subnet_ids
  route_table_ids    = var.endpoint_route_tables
  security_group_ids = [module.eks_cluster.eks_cluster_managed_security_group_id]
}

# Create Fargate profile for default and kube-system namespace
module "eks_fargate_profile_default" {
  source                     = "../eks-fargate-profile"
  fargate_profile_depends_on = "none"
  name                       = "default-fargate"
  tags                       = var.tags
  subnet_ids                 = var.local_subnet_ids
  cluster_name               = module.eks_cluster.eks_cluster_id

  selectors = {
    default     = {}
    kube-system = {}
  }
}

# Create Fargate profile for default and kube-system namespace
module "eks_fargate_profile_default_egress" {
  source                     = "../eks-fargate-profile"
  fargate_profile_depends_on = module.eks_fargate_profile_default.eks_fargate_profile_status
  name                       = "default-egress-fargate"
  tags                       = var.tags
  subnet_ids                 = var.private_subnet_ids
  cluster_name               = module.eks_cluster.eks_cluster_id

  selectors = {
    default = {
      placement = "egress"
    }
    kube-system = {
      placement = "egress"
    }
  }
}

# Create Fargate profile for default and kube-system namespace
module "eks_fargate_profile_appmesh" {
  source                     = "../eks-fargate-profile"
  fargate_profile_depends_on = module.eks_fargate_profile_default.eks_fargate_profile_status
  name                       = "appmesh-system"
  tags                       = var.tags
  subnet_ids                 = var.private_subnet_ids
  cluster_name               = module.eks_cluster.eks_cluster_id

  selectors = {
    appmesh-system            = {},
    howto-k8s-ingress-gateway = {}
  }
}

module "eks_node_group" {
  source             = "../eks-node-group"
  name               = "${var.name}-node-group"
  tags               = merge(var.tags, map("Name", "${var.name}-node-group"))
  subnet_ids         = var.private_subnet_ids
  instance_types     = var.instance_types
  desired_size       = var.desired_size
  min_size           = var.min_size
  max_size           = var.max_size
  cluster_name       = module.eks_cluster.eks_cluster_id
  kubernetes_version = var.kubernetes_version
  kubernetes_labels  = var.kubernetes_labels
  disk_size          = var.disk_size
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
  alias                  = "eks"
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
  version = "3.4.0"

  k8s_cluster_type = "eks"
  k8s_namespace    = "kube-system"

  k8s_cluster_name = module.eks_cluster.eks_cluster_id
  aws_tags         = merge(var.tags, map("FargateProfile", module.eks_fargate_profile_default_egress.eks_fargate_profile_id))

  k8s_pod_labels = {
    placement = "egress"
  }
}

module "external-dns" {
  providers = {
    kubernetes = kubernetes.eks
  }
  source = "../external-dns"

  eks_cluster_name = module.eks_cluster.eks_cluster_id
  tags             = merge(var.tags, map("FargateProfile", module.eks_fargate_profile_default_egress.eks_fargate_profile_id))
  owner_id         = var.private_hosted_zone_id
  kubernetes_resources_labels = {
    placement = "egress"
  }
}
