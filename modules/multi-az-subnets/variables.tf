variable "name" {
  type        = string
  description = "Application or solution name"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Additional tags (e.g. map(`BusinessUnit`,`XYZ`)"
}

variable "availability_zones" {
  type        = list(string)
  description = "List of Availability Zones (e.g. `['us-east-1a', 'us-east-1b', 'us-east-1c']`)"
}

variable "max_subnets" {
  default     = "6"
  description = "Maximum number of subnets that can be created. The variable is used for CIDR blocks calculation"
}

variable "type" {
  type        = string
  default     = "private"
  description = "Type of subnets to create"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "cidr_block" {
  type        = string
  description = "Base CIDR block which is divided into subnet CIDR blocks (e.g. `10.0.0.0/16`)"
}

variable "private_network_acl_egress" {
  description = "Egress network ACL rules"
  type        = list(map(string))

  default = [
    {
      rule_no    = 100
      action     = "allow"
      cidr_block = "0.0.0.0/0"
      from_port  = 0
      to_port    = 0
      protocol   = "-1"
    },
  ]
}

variable "private_network_acl_ingress" {
  description = "Egress network ACL rules"
  type        = list(map(string))

  default = [
    {
      rule_no    = 100
      action     = "allow"
      cidr_block = "0.0.0.0/0"
      from_port  = 0
      to_port    = 0
      protocol   = "-1"
    },
  ]
}

variable "tgw_id" {
  description = "Transit Gateway ID to route through"
  default     = ""
}
