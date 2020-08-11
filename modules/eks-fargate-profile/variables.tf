variable "name" {
  type        = string
  description = "Solution name, e.g. 'app' or 'cluster'"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Additional tags (e.g. `{ BusinessUnit = \"XYZ\" }`"
}

variable "cluster_name" {
  type        = string
  description = "The name of the EKS cluster"
}

variable "subnet_ids" {
  description = "Identifiers of private EC2 Subnets to associate with the EKS Fargate Profile. These subnets must have the following resource tag: kubernetes.io/cluster/CLUSTER_NAME (where CLUSTER_NAME is replaced with the name of the EKS Cluster)"
  type        = list(string)
}

variable "selectors" {
  type        = map(map(string))
  description = ""
}

# There is a bug with Fargate Profiles attempting to create in parallel in Terraform which isn't allowed by EKS Fargate
# https://github.com/terraform-providers/terraform-provider-aws/issues/13372
variable "fargate_profile_depends_on" {
  # the value is irrelevant; we only care about
  # dependencies for this one.
  type = any
}
