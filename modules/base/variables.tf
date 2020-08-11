variable "tags" {
  type        = map(string)
  default     = {}
  description = "Additional tags (e.g. map(`BusinessUnit`,`XYZ`)"
}

variable "name" {
  type        = string
  description = "Solution name, e.g. 'app' or 'cluster'"
  default     = ""
}

#####

variable "vpc_cidr_block" {
  type        = string
  description = "CIDR for the VPC"
}

variable "vpc_secondary_cidr_block" {
  type        = string
  description = "VPC secondary CIDR block"
}

#####

variable "availability_zones" {
  type        = list(string)
  description = "List of Availability Zones (e.g. `['us-east-1a', 'us-east-1b', 'us-east-1c']`)"
}

#####

variable "private_hosted_domain_name" {
  description = "Private hosted zone domain name"
  default     = "example.com"
}
