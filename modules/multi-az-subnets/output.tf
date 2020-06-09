output "az_subnet_ids" {
  value = zipmap(
    var.availability_zones,
    aws_subnet.this.*.id
  )
  description = "Map of AZ names to subnet IDs"
}

output "az_route_table_ids" {
  value = zipmap(
    var.availability_zones,
    aws_route_table.this.*.id
  )
  description = "Map of AZ names to Route Table IDs"
}

output "az_subnet_arns" {
  value = zipmap(
    var.availability_zones,
    aws_subnet.this.*.arn
  )
  description = "Map of AZ names to subnet ARNs"
}