locals {
  gateway_services = ["dynamodb", "s3"]
  gateways         = toset([for service in var.services : service if contains(local.gateway_services, service)])
  interfaces       = toset([for service in var.services : service if ! contains(local.gateway_services, service)])
}

data "aws_vpc_endpoint_service" "service" {
  for_each = var.services
  service  = each.key
}

resource "aws_vpc_endpoint" "gateway" {
  for_each        = local.gateways
  vpc_id          = var.vpc_id
  service_name    = data.aws_vpc_endpoint_service.service[each.key].service_name
  tags            = merge(var.tags, map("Name", "${var.name}-${each.key}-endpoint"))
  route_table_ids = var.route_table_ids
}

resource "aws_vpc_endpoint" "interface" {
  for_each            = local.interfaces
  vpc_id              = var.vpc_id
  service_name        = data.aws_vpc_endpoint_service.service[each.key].service_name
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  security_group_ids  = var.security_group_ids
  tags                = merge(var.tags, map("Name", "${var.name}-${each.key}-endpoint"))
  subnet_ids          = var.subnet_ids
}
