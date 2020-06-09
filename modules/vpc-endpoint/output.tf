output "gateway_endpoint_ids" {
  value       = values(aws_vpc_endpoint.gateway)[*].id
  description = "The ids for a gateway endpoint"
}


output "interface_endpoint_ids" {
  value       = values(aws_vpc_endpoint.interface)[*].id
  description = "The ids for a interface endpoint"
}