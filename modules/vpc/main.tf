resource "aws_vpc" "default" {
  cidr_block                       = var.cidr_block
  instance_tenancy                 = var.instance_tenancy
  enable_dns_hostnames             = var.enable_dns_hostnames
  enable_dns_support               = var.enable_dns_support
  enable_classiclink               = var.enable_classiclink
  enable_classiclink_dns_support   = var.enable_classiclink_dns_support
  assign_generated_ipv6_cidr_block = true
  tags                             = var.tags
}

# Associate a second cidr range to the VPC for the Fargate pod subnets
resource "aws_vpc_ipv4_cidr_block_association" "secondary_cidr" {
    vpc_id     = aws_vpc.default.id
    cidr_block = var.secondary_cidr_block
}

# If `aws_default_security_group` is not defined, it would be created implicitly with access `0.0.0.0/0`
resource "aws_default_security_group" "default" {
  count  = var.enable_default_security_group_with_custom_rules ? 1 : 0
  vpc_id = aws_vpc.default.id

  tags = {
    Name = "Default Security Group"
  }
}

resource "aws_internet_gateway" "default" {
  vpc_id = aws_vpc.default.id
  tags   = var.tags
}