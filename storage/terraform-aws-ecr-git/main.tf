#-------------------------------
# OIDC Trust for GitHub Actions
#-------------------------------
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [var.git_root_ca_thumbprint]
}

#-------------------------------
# IAM Role for GitHub Actions to Push Images
#-------------------------------
resource "aws_iam_role" "git_push_image_role" {
  for_each = { for cfg in var.repository_config : cfg.git_repository => cfg }

  name = each.value.assume_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Federated = "arn:aws:iam::${var.account_id}:oidc-provider/token.actions.githubusercontent.com"
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${var.git_organization}/${each.key}:*"
          }
        }
      }
    ]
  })

  tags = {
    Name        = each.value.assume_role_name
    repository  = each.key
    Environment = var.environment
  }
}

#-------------------------------
# IAM Policy: ECR Push Permissions
#-------------------------------
resource "aws_iam_policy" "git_ecr_push_policy" {
  for_each = { for cfg in var.repository_config : cfg.git_repository => cfg }

  name = "${each.value.ecr_repostory}-ecr-push-policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ecr:CompleteLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:InitiateLayerUpload",
          "ecr:BatchCheckLayerAvailability",
          "ecr:PutImage",
          "ecr:BatchGetImage"
        ],
        Resource = "arn:aws:ecr:${var.region}:${var.account_id}:repository/${each.value.ecr_repostory}"
      },
      {
        Effect   = "Allow",
        Action   = "ecr:GetAuthorizationToken",
        Resource = "*"
      }
    ]
  })

  tags = {
    Name        = "${each.value.ecr_repostory}-ecr-push-policy"
    Environment = var.environment
  }
}

#-------------------------------
# Attach IAM Policy to Role
#-------------------------------
resource "aws_iam_role_policy_attachment" "attach_push_policy" {
  for_each = { for cfg in var.repository_config : cfg.git_repository => cfg }

  role       = aws_iam_role.git_push_image_role[each.key].name
  policy_arn = aws_iam_policy.git_ecr_push_policy[each.key].arn
}

#-------------------------------
# Create ECR Repositories
#-------------------------------
resource "aws_ecr_repository" "image_repositories" {
  for_each = { for cfg in var.repository_config : cfg.git_repository => cfg }

  name                 = each.value.ecr_repostory
  image_tag_mutability = each.value.image_tag_mutability

  image_scanning_configuration {
    scan_on_push = each.value.scan_on_push
  }

  tags = {
    Name        = each.value.ecr_repostory
    Environment = var.environment
  }
}
