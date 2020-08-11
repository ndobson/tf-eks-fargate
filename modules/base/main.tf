# Create a VPC for the EKS cluster
module "vpc" {
  source               = "../vpc"
  cidr_block           = var.vpc_cidr_block
  secondary_cidr_block = var.vpc_secondary_cidr_block
  tags                 = var.tags
}

# Create subnets in the primary cidr range across all availability zones
module "public_subnets" {
  source             = "../multi-az-subnets"
  name               = var.name
  availability_zones = var.availability_zones
  vpc_id             = module.vpc.vpc_id
  igw_id             = module.vpc.igw_id
  cidr_block         = var.vpc_cidr_block
  type               = "public"
  max_subnets        = length(var.availability_zones)
  tags               = merge(var.tags, map("kubernetes.io/role/internal-elb", "1"), map("kubernetes.io/role/elb", "1"))
}

# Create subnets in the secondary cidr range across all availability zones
module "private_subnets" {
  source             = "../multi-az-subnets"
  name               = var.name
  availability_zones = var.availability_zones
  vpc_id             = module.vpc.vpc_id
  cidr_block         = module.vpc.vpc_secondary_cidr_block
  az_ngw_ids         = module.public_subnets.az_ngw_ids
  type               = "private"
  max_subnets        = length(var.availability_zones)
  tags               = var.tags
}

resource "aws_route53_zone" "private" {
  name = var.private_hosted_domain_name

  vpc {
    vpc_id = module.vpc.vpc_id
  }
}
