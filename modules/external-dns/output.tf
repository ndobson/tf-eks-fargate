output "aws_iam_policy_arn" {
  value = aws_iam_policy.external_dns.arn
}

output "aws_iam_role_arn" {
  value = aws_iam_role.external_dns.arn
}

output "kubernetes_deployment" {
  value = "${kubernetes_deployment.external_dns.metadata.0.namespace}/${kubernetes_deployment.external_dns.metadata.0.name}"
}