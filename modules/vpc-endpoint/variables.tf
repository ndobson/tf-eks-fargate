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

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "route_table_ids" {
  type        = list(string)
  default     = []
  description = "List of route table ids to associate to gateway endpoints"
}

variable "subnet_ids" {
  type        = list(string)
  default     = []
  description = "List of subnet ids to create network interfaces for interface endpoints"
}

variable "security_group_ids" {
  type        = list(string)
  description = "List of security group ids for interface endpoints"
}

variable "services" {
  type        = set(string)
  description = "List of VPC Endpoint service names"
}