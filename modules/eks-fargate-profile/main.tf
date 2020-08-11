locals {
  tags = merge(
    var.tags,
    {
      "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    }
  )
}

data "aws_iam_policy_document" "assume_role" {
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
  name               = var.name
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  tags               = local.tags
}

resource "aws_iam_role_policy_attachment" "amazon_eks_fargate_pod_execution_role_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
  role       = aws_iam_role.default.name
}

resource "aws_eks_fargate_profile" "default" {
  depends_on             = [var.fargate_profile_depends_on]
  cluster_name           = var.cluster_name
  fargate_profile_name   = var.name
  pod_execution_role_arn = aws_iam_role.default.arn
  subnet_ids             = var.subnet_ids
  tags                   = local.tags

  dynamic "selector" {
    for_each = var.selectors
    content {
      namespace = selector.key
      labels    = selector.value
    }
  }
}
