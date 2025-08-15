
# This VPC INI doesnt work for pod SG at the moment. Not sure why? Have to dig deeper.
# Create IAM role for IRSA for aws-node (VPC CNI)
data "aws_iam_policy_document" "vpc_cni_assume_role_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.eks_oidc_provider.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks_oidc_provider.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:aws-node"]
    }
  }
}

resource "aws_iam_role" "vpc_cni_irsa_role" {
  name               = "${var.cluster_name}-vpc-cni-irsa"
  assume_role_policy = data.aws_iam_policy_document.vpc_cni_assume_role_policy.json
}

# Attach required AWS managed policy for CNI
resource "aws_iam_role_policy_attachment" "vpc_cni_policy_attach" {
  role       = aws_iam_role.vpc_cni_irsa_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

# Optional: attach custom inline permissions if needed (like for SGP)
resource "aws_iam_role_policy" "vpc_cni_custom_permissions" {
  name = "${var.cluster_name}-vpc-cni-additional-permissions"
  role = aws_iam_role.vpc_cni_irsa_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ec2:AttachNetworkInterface",
          "ec2:CreateNetworkInterface",
          "ec2:DeleteNetworkInterface",
          "ec2:DescribeInstances",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeSecurityGroups",
          "ec2:DetachNetworkInterface",
          "ec2:ModifyNetworkInterfaceAttribute",
          "ec2:AssignPrivateIpAddresses",
          "ec2:UnassignPrivateIpAddresses"
        ],
        Resource = "*"
      }
    ]
  })
}

# Update EKS Addon to use the IRSA role
resource "aws_eks_addon" "vpc_cni" {
  cluster_name                = aws_eks_cluster.eks_cluster.name
  addon_name                  = "vpc-cni"
  addon_version               = var.vpc_cni_addon_version
  resolve_conflicts_on_update = "OVERWRITE"

  configuration_values = jsonencode({
    env = {
      ENABLE_POD_ENI = "true"
    }
  })

  service_account_role_arn = aws_iam_role.vpc_cni_irsa_role.arn

  depends_on = [
    aws_eks_cluster.eks_cluster,
    aws_iam_role_policy_attachment.vpc_cni_policy_attach,
    aws_iam_role_policy.vpc_cni_custom_permissions
  ]
}
