output "vpc_id" {
  value       = module.vpc.vpc_id
  description = "The ID of the VPC"
}

output "vpc_cidr_block" {
  value       = module.vpc.vpc_cidr_block
  description = "The CIDR block of the VPC"
}

output "vpc_main_route_table_id" {
  value       = module.vpc.vpc_main_route_table_id
  description = "The ID of the main route table associated with this VPC"
}

output "vpc_default_network_acl_id" {
  value       = module.vpc.vpc_default_network_acl_id
  description = "The ID of the network ACL created by default on VPC creation"
}

output "vpc_default_security_group_id" {
  value       = module.vpc.vpc_default_security_group_id
  description = "The ID of the security group created by default on VPC creation"
}

output "vpc_default_route_table_id" {
  value       = module.vpc.vpc_default_route_table_id
  description = "The ID of the route table created by default on VPC creation"
}

###

output "public_az_subnet_ids" {
  value       = module.public_subnets.az_subnet_ids
  description = "Map of public AZ names to subnet IDs"
}

output "public_az_route_table_ids" {
  value       = module.public_subnets.az_route_table_ids
  description = "Map of public AZ names to Route Table IDs"
}

output "public_az_subnet_arns" {
  value       = module.public_subnets.az_subnet_arns
  description = "Map of public AZ names to subnet ARNs"
}

output "private_az_subnet_ids" {
  value       = module.private_subnets.az_subnet_ids
  description = "Map of private AZ names to subnet IDs"
}

output "private_az_route_table_ids" {
  value       = module.private_subnets.az_route_table_ids
  description = "Map of private AZ names to Route Table IDs"
}

output "private_az_subnet_arns" {
  value       = module.private_subnets.az_subnet_arns
  description = "Map of private AZ names to subnet ARNs"
}

output "private_hosted_zone_id" {
  value       = aws_route53_zone.private.zone_id
  description = "Map of private AZ names to subnet ARNs"
}

output "private_hosted_name_servers" {
  value       = aws_route53_zone.private.name_servers
  description = "Map of private AZ names to subnet ARNs"
}
