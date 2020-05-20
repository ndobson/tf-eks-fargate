  
data "aws_caller_identity" "current" {}

data "aws_eks_cluster" "selected" {
  name  = var.eks_cluster_name
}

data "aws_iam_policy_document" "eks_oidc_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"
    condition {
      test     = "StringEquals"
      variable = "${replace(data.aws_eks_cluster.selected.identity[0].oidc[0].issuer, "https://", "")}:sub"
      values = [
        "system:serviceaccount:${var.kubernetes_namespace}:${var.kubernetes_resources_name_prefix}external-dns"
      ]
    }
    principals {
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${replace(data.aws_eks_cluster.selected.identity[0].oidc[0].issuer, "https://", "")}"
      ]
      type = "Federated"
    }
  }
}

resource "aws_iam_policy" "external_dns" {
  name = var.aws_iam_policy_name
  path = "/"
  description = "Allows access to resources needed to run external dns."

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "route53:ChangeResourceRecordSets"
      ],
      "Resource": [
        "arn:aws:route53:::hostedzone/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "route53:ListHostedZones",
        "route53:ListResourceRecordSets"
      ],
      "Resource": [
        "*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role" "external_dns" {
  name               = var.aws_iam_role_name
  assume_role_policy = data.aws_iam_policy_document.eks_oidc_assume_role.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "external_dns" {
  role = aws_iam_role.external_dns.name
  policy_arn = aws_iam_policy.external_dns.arn
}
