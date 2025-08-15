#-------------------------------
# Variables
#-------------------------------
variable "region" {
  type        = string
  description = "AWS Region"
}

variable "account_id" {
  type        = string
  description = "AWS Account ID"
}

variable "environment" {
  type        = string
  description = "Deployment environment (e.g. dev, prod)"
}

variable "git_organization" {
  type        = string
  description = "GitHub organization name"
}

variable "git_root_ca_thumbprint" {
  type        = string
  default     = "6938fd4d98bab03faadb97b34396831e3780aea1"
  description = "GitHub Actions OIDC root CA thumbprint (monitor for changes)"
}

variable "repository_config" {
  type = list(object({
    ecr_repostory        = string
    assume_role_name     = string
    git_repository       = string
    image_tag_mutability = string
    scan_on_push         = bool
  }))
  description = "ECR repository config to push image from"
}
