#####################
# IAM OIDC Trust Policy Document
#####################
data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "github_oidc_trust" {
  for_each = {
    for cfg in var.bucket_path_config : cfg.path => {
      repository_name = cfg.git_repository
    }
  }

  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type = "Federated"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"
      ]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:${var.git_organization}/${each.value.repository_name}:*"
      ]
    }
  }
}
