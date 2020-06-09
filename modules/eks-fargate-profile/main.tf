locals {
  tags = merge(
    var.tags,
    {
      "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    }
  )
}

data "aws_iam_policy_document" "assume_role" {
  count = var.enabled ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["eks-fargate-pods.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "default" {
  count              = var.enabled ? 1 : 0
  name               = var.name
  assume_role_policy = join("", data.aws_iam_policy_document.assume_role.*.json)
  tags               = local.tags
}

resource "aws_iam_role_policy_attachment" "amazon_eks_fargate_pod_execution_role_policy" {
  count      = var.enabled ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
  role       = join("", aws_iam_role.default.*.name)
}

resource "aws_eks_fargate_profile" "default" {
  depends_on = [var.fargate_profile_depends_on]
  count                  = var.enabled ? 1 : 0
  cluster_name           = var.cluster_name
  fargate_profile_name   = var.name
  pod_execution_role_arn = join("", aws_iam_role.default.*.arn)
  subnet_ids             = var.subnet_ids
  tags                   = local.tags

  dynamic "selector" {
    for_each = var.selectors
    content {
      namespace = selector.key
      labels = selector.value
    }
  }
}