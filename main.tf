provider "aws" {
  region = var.region
}

data "aws_eks_cluster_auth" "aws_iam_authenticator" {
  name = module.eks_fargate_cluster.eks_cluster_id
}

locals {
  tags = merge(var.tags, map("Name", var.name), map("kubernetes.io/cluster/${var.name}", "shared"))
}

###
# Base Infrastructure
###

module "base" {
  source                     = "./modules/base"
  name                       = var.name
  tags                       = local.tags
  vpc_cidr_block             = var.vpc_cidr_block
  vpc_secondary_cidr_block   = var.vpc_secondary_cidr_block
  availability_zones         = var.availability_zones
  private_hosted_domain_name = var.private_hosted_domain_name
}

###
# EKS Cluster
###

module "eks_fargate_cluster" {
  source                      = "./modules/eks-fargate-cluster"
  name                        = var.name
  tags                        = local.tags
  region                      = var.region
  vpc_id                      = module.base.vpc_id
  cluster_subnet_ids          = concat(values(module.base.private_az_subnet_ids), values(module.base.public_az_subnet_ids))
  kubernetes_version          = var.kubernetes_version
  oidc_provider_enabled       = var.oidc_provider_enabled
  map_additional_aws_accounts = var.map_additional_aws_accounts
  map_additional_iam_roles    = var.map_additional_iam_roles
  map_additional_iam_users    = var.map_additional_iam_users
  private_subnet_ids          = values(module.base.private_az_subnet_ids)
  endpoint_route_tables       = concat(values(module.base.private_az_route_table_ids), values(module.base.public_az_route_table_ids))
  private_hosted_zone_id      = module.base.private_hosted_zone_id
}

# ###
# # Deploy demo application
# ###

# Create application namespace Fargate profile
module "eks_fargate_profile_2048-game" {
  source                     = "./modules/eks-fargate-profile"
  fargate_profile_depends_on = "none"
  name                       = "2048-game"
  tags                       = var.tags
  subnet_ids                 = values(module.base.private_az_subnet_ids)
  cluster_name               = module.eks_fargate_cluster.eks_cluster_id

  selectors = {
    "2048-game" = {}
  }
}

# Deploy test app
module "k8s_2048-game" {
  source  = "./modules/2048-game"
  depends = module.eks_fargate_profile_2048-game.eks_fargate_profile_status # For dependency mapping
}
