# Static Website with GitHub Actions Deployment

## Overview
This Terraform module creates a complete static website hosting solution with:
- S3 bucket for file storage
- CloudFront CDN for global distribution
- GitHub Actions OIDC integration for secure deployments
- Route53 DNS configuration
- Fine-grained access controls

## Features
- **Secure Deployments**: GitHub Actions OIDC authentication
- **Global CDN**: CloudFront distribution with HTTPS
- **Versioned Storage**: S3 versioning for rollback capability
- **Path-Based Access Control**: Separate IAM roles per path prefix
- **Automated DNS**: Route53 alias record configuration

## Requirements
- Terraform >= 1.12.1
- AWS Provider >= 5.0
- Existing ACM certificate
- Route53 hosted zone
- GitHub repository with Actions enabled

## Usage
```hcl
module "static_website" {
  source = "./path/to/module"

  environment = "production"
  bucket_name = "my-static-website"

  bucket_domain_name            = "static.example.com"
  bucket_domain_cert_arn        = "arn:aws:acm:us-east-1:123456789012:certificate/abcd1234"
  bucket_doamin_route53_zone_id = "Z1234567890ABC"

  git_organization = "my-org"

  bucket_path_config = [
    {
      path             = "assets"
      assume_role_name = "github-assets-upload"
      git_repository   = "frontend-repo"
    },
    {
      path             = "docs"
      assume_role_name = "github-docs-upload"
      git_repository   = "documentation-repo"
    }
  ]
}
```

## Input Variables

### Required Variables
| Name | Description | Type |
|------|-------------|------|
| environment | Deployment environment | string |
| bucket_name | S3 bucket name | string |
| bucket_domain_name | Website domain name | string |
| bucket_domain_cert_arn | ACM certificate ARN | string |
| bucket_doamin_route53_zone_id | Route53 zone ID | string |
| git_organization | GitHub organization name | string |
| bucket_path_config | Path configuration list | list(object) |

### Path Configuration Object
| Key | Description | Type | Required |
|-----|-------------|------|----------|
| path | S3 path prefix | string | Yes |
| assume_role_name | IAM role name | string | Yes |
| git_repository | GitHub repository name | string | Yes |

## Module Components

### 1. S3 Bucket
- Versioning enabled
- Public access configured for web hosting
- Per-path access policies

### 2. IAM Configuration
- OIDC trust with GitHub Actions
- Separate IAM role per path prefix
- Fine-grained S3 permissions:
  - Put/Delete objects in assigned path
  - List bucket with path prefix filter

### 3. CloudFront Distribution
- S3 origin with OAC (Origin Access Control)
- HTTPS enforcement
- Global edge caching
- PriceClass optimization

### 4. DNS Configuration
- Route53 alias record
- Points to CloudFront distribution

## GitHub Actions Workflow Example
```yaml
name: Deploy to S3

on:
  push:
    branches: [ main ]

permissions:
  id-token: write
  contents: read

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v3

      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          role-to-assume: arn:aws:iam::123456789012:role/github-assets-upload
          aws-region: us-east-1

      - name: Sync files
        run: |
          aws s3 sync ./assets s3://my-static-website/assets/ --delete
```

## Security Best Practices
1. Use separate IAM roles per repository/path
2. Enable S3 versioning for rollback capability
3. Restrict CloudFront to specific S3 paths
4. Monitor deployment activity with CloudTrail
5. Regularly review OIDC trust policies
6. Use HTTPS and modern TLS protocols

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
