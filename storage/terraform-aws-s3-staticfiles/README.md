
# Terraform Module: Static File Hosting with S3, CloudFront, and GitHub Actions Integration

This Terraform module provisions an S3 bucket for hosting static files, configures IAM roles for GitHub Actions to upload files, applies appropriate bucket policies, and exposes the content via CloudFront with a custom domain using Route53.

---

## 🔧 Features

- S3 bucket with versioning for static file storage
- IAM roles and policies for GitHub Actions OIDC authentication
- Public read and scoped upload permissions
- CloudFront CDN for low-latency global delivery
- Route53 alias for custom domain support

---

## ✅ Requirements

- Terraform 1.0+
- AWS credentials configured
- Domain hosted in Route53
- Valid ACM certificate in `us-east-1` for CloudFront

---

## 🚀 Usage

```hcl
module "static_site" {
  source = "./modules/static_site"

  environment                   = "prod"
  git_organization              = "my-org"
  bucket_name                   = "static-files-prod"
  bucket_domain_name            = "static.my-domain.com"
  bucket_domain_cert_arn        = "arn:certificate"
  bucket_doamin_route53_zone_id = "zoneid"
  bucket_path_config = [
    {
      path               = "docs"
      assume_role_name   = "docs-uploader"
      git_repository = "my-org/docs-repo"
    },
    {
      path               = "assets"
      assume_role_name   = "assets-uploader"
      git_repository = "my-org/assets-repo"
    }
  ]
}
