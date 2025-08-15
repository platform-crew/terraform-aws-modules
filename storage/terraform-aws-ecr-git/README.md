# Terraform Module: ECR GitHub OIDC Push

This Terraform module provisions Amazon ECR repositories and configures GitHub Actions to authenticate with AWS using OIDC for pushing container images. It sets up:

- An IAM OIDC provider for GitHub Actions
- IAM role and policy for ECR access
- One ECR repository per GitHub repository

---

## 🚀 Use Case

Enables GitHub Actions workflows in specified repositories to push Docker images securely to ECR without long-lived AWS credentials.

---

## ✅ Features

- Creates an OIDC identity provider for GitHub
- Configures an IAM role with trust policy for GitHub Actions
- Grants least-privilege access to ECR push actions
- Creates ECR repositories and enables image scanning

---

## 📥 Inputs

| Name                    | Type        | Default     | Description                                                                 |
|-------------------------|-------------|-------------|-----------------------------------------------------------------------------|
| `region`                | `string`    | n/a         | AWS region where resources will be created                                 |
| `account_id`            | `string`    | n/a         | AWS account ID                                                              |
| `environment`           | `string`    | n/a         | Deployment environment (e.g., `dev`, `prod`)                                |
| `git_organization`      | `string`    | n/a         | GitHub organization name                                                    |
| `git_repositories`      | `list(string)` | `[]`     | List of GitHub repo names allowed to push to ECR                           |
| `git_root_ca_thumbprint`| `string`    | `6938fd...` | GitHub's OIDC root CA thumbprint (update if changed)                        |
| `ecr_scan_on_push`      | `bool`      | `true`      | Enable image vulnerability scanning on push                                 |
| `image_tag_mutability`  | `string`    | `IMMUTABLE` | Whether ECR tags are mutable or immutable (`IMMUTABLE` or `MUTABLE`)        |

---

## 📤 Outputs

This module does **not** currently define any outputs. You can extend it to expose:
- ECR repository URLs
- IAM role ARN
- Policy ARN

---

## 🧾 Example Usage

```hcl
module "ecr_github_push" {
  source  = "./modules/ecr-github-oidc"
  region  = "us-west-2"

  account_id           = "123456789012"
  environment          = "dev"
  git_organization     = "my-org"
  git_repositories     = ["my-service", "another-service"]
  image_tag_mutability = "IMMUTABLE"
}
