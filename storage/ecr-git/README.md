# GitHub Actions to AWS ECR Terraform Module

## Overview
This Terraform module configures secure GitHub Actions workflows to push Docker images to AWS ECR repositories using OpenID Connect (OIDC) for authentication.

## Features
- **Secure Authentication**: Uses GitHub Actions OIDC provider for temporary credentials
- **Repository Isolation**: Separate IAM roles per GitHub repository
- **Fine-Grained Permissions**: Minimal required ECR permissions
- **Automatic Setup**: Creates both IAM roles and ECR repositories
- **Security Scanning**: Configurable image scanning on push
- **Tag Management**: Configurable image tag mutability

## Requirements
- Terraform >= 1.12.1
- AWS Provider >= 5.0
- GitHub repository with Actions enabled
- AWS account with ECR permissions

## Usage
```hcl
module "github_ecr_access" {
  source = "./path/to/module"

  region          = "us-east-1"
  account_id      = "123456789012"
  environment     = "production"
  git_organization = "my-org"

  repository_config = [
    {
      ecr_repostory        = "frontend-app"
      assume_role_name     = "github-frontend-ecr-push"
      git_repository       = "frontend-repo"
      image_tag_mutability = "MUTABLE"
      scan_on_push         = true
    },
    {
      ecr_repostory        = "backend-service"
      assume_role_name     = "github-backend-ecr-push"
      git_repository       = "backend-repo"
      image_tag_mutability = "IMMUTABLE"
      scan_on_push         = true
    }
  ]
}
```

## Input Variables

### Required Variables
| Name | Description | Type |
|------|-------------|------|
| region | AWS region for resources | string |
| account_id | AWS account ID | string |
| environment | Deployment environment | string |
| git_organization | GitHub organization name | string |
| repository_config | List of repository configurations | list(object) |

### Optional Variables
| Name | Description | Type | Default |
|------|-------------|------|---------|
| git_root_ca_thumbprint | GitHub OIDC provider thumbprint | string | "6938fd4d98bab03faadb97b34396831e3780aea1" |

### Repository Config Object
| Key | Description | Type | Required |
|-----|-------------|------|----------|
| ecr_repostory | ECR repository name | string | Yes |
| assume_role_name | IAM role name for GitHub | string | Yes |
| git_repository | GitHub repository name | string | Yes |
| image_tag_mutability | MUTABLE or IMMUTABLE | string | Yes |
| scan_on_push | Enable image scanning | bool | Yes |

## Module Components

### 1. OIDC Integration
- Configures GitHub Actions as OIDC identity provider
- Uses GitHub's token service endpoint
- Includes root CA thumbprint verification

### 2. IAM Roles & Policies
- Creates dedicated IAM role per repository
- Configures OIDC trust relationship
- Attaches minimal ECR permissions:
  - Image push permissions
  - Layer upload operations
  - Authorization token access

### 3. ECR Repositories
- Creates configured ECR repositories
- Sets image scanning preferences
- Configures tag immutability
- Applies environment tags

## GitHub Actions Workflow Example
```yaml
name: Push to ECR

on:
  push:
    branches: [ main ]

permissions:
  id-token: write
  contents: read

jobs:
  build-and-push:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v3

      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          role-to-assume: arn:aws:iam::123456789012:role/github-frontend-ecr-push
          aws-region: us-east-1

      - name: Login to Amazon ECR
        id: login-ecr
        uses: aws-actions/amazon-ecr-login@v1

      - name: Build, tag, and push image
        run: |
          docker build -t ${{ steps.login-ecr.outputs.registry }}/frontend-app:${{ github.sha }} .
          docker push ${{ steps.login-ecr.outputs.registry }}/frontend-app:${{ github.sha }}
```

## Security Best Practices
1. Use IMMUTABLE tags for production repositories
2. Enable scan_on_push for vulnerability detection
3. Regularly rotate the GitHub OIDC thumbprint
4. Limit repository access to specific GitHub branches if needed
5. Monitor ECR push events with CloudTrail
6. Use separate roles per repository for least privilege

## Maintenance
To update configurations:
1. Modify the Terraform variables
2. Review changes:
   ```bash
   terraform plan
   ```
3. Apply changes:
   ```bash
   terraform apply
   ```

## Cleanup
To remove all resources:
```bash
terraform destroy
```
