output "security_group_id" {
  description = "ID of the EKS cluster Security Group"
  value       = module.eks_cluster.security_group_id
}

output "security_group_arn" {
  description = "ARN of the EKS cluster Security Group"
  value       = module.eks_cluster.security_group_arn
}

output "security_group_name" {
  description = "Name of the EKS cluster Security Group"
  value       = module.eks_cluster.security_group_name
}

output "eks_cluster_id" {
  description = "The name of the cluster"
  value       = module.eks_cluster.eks_cluster_id
  depends_on  = [ null_resource.coredns_patch, module.alb_ingress_controller ] # for dependency mapping
}

output "eks_cluster_arn" {
  description = "The Amazon Resource Name (ARN) of the cluster"
  value       = module.eks_cluster.eks_cluster_arn
}

output "eks_cluster_endpoint" {
  description = "The endpoint for the Kubernetes API server"
  value       = module.eks_cluster.eks_cluster_endpoint
}

output "eks_cluster_version" {
  description = "The Kubernetes server version of the cluster"
  value       = module.eks_cluster.eks_cluster_version
}

output "eks_cluster_identity_oidc_issuer" {
  description = "The OIDC Identity issuer for the cluster"
  value       = module.eks_cluster.eks_cluster_identity_oidc_issuer
}

output "eks_cluster_identity_oidc_issuer_arn" {
  description = "The OIDC Identity issuer ARN for the cluster that can be used to associate IAM roles with a service account"
  value       = module.eks_cluster.eks_cluster_identity_oidc_issuer_arn
}

output "eks_cluster_certificate_authority_data" {
  description = "The Kubernetes cluster certificate authority data"
  value       = module.eks_cluster.eks_cluster_certificate_authority_data
}

output "eks_cluster_managed_security_group_id" {
  description = "Security Group ID that was created by EKS for the cluster. EKS creates a Security Group and applies it to ENI that is attached to EKS Control Plane master nodes and to any managed workloads"
  value       = module.eks_cluster.eks_cluster_managed_security_group_id
}

output "eks_cluster_role_arn" {
  description = "ARN of the EKS cluster IAM role"
  value       = module.eks_cluster.eks_cluster_role_arn
}

output "kubernetes_config_map_id" {
  description = "ID of `aws-auth` Kubernetes ConfigMap"
  value       = module.eks_cluster.kubernetes_config_map_id
}

#####

output "eks_fargate_profile_role_arn" {
  description = "ARN of the EKS Fargate Profile IAM role"
  value       = module.eks_fargate_profile_default.eks_fargate_profile_role_arn
}

output "eks_fargate_profile_role_name" {
  description = "Name of the EKS Fargate Profile IAM role"
  value       = module.eks_fargate_profile_default.eks_fargate_profile_role_name
}

output "eks_fargate_profile_id" {
  description = "EKS Cluster name and EKS Fargate Profile name separated by a colon"
  value       = module.eks_fargate_profile_default.eks_fargate_profile_id
}

output "eks_fargate_profile_arn" {
  description = "Amazon Resource Name (ARN) of the EKS Fargate Profile"
  value       = module.eks_fargate_profile_default.eks_fargate_profile_arn
}

output "eks_fargate_profile_status" {
  description = "Status of the EKS Fargate Profile"
  value       = module.eks_fargate_profile_default.eks_fargate_profile_status
}

#####

output "aws_iam_role_arn" {
  description = "ARN of the IAM role that is being utilized by the deployed controller."
  value       = module.alb_ingress_controller.aws_iam_role_arn
}