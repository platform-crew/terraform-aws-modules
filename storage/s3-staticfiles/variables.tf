variable "environment" {
  type        = string
  description = "Environment"
}

variable "git_organization" {
  type        = string
  description = "GitHub organization name"
}

variable "bucket_name" {
  type        = string
  description = "S3 bucket name for static files"
}

variable "bucket_domain_name" {
  type        = string
  description = "Domain name of the bucket"
}

variable "bucket_domain_cert_arn" {
  type        = string
  description = "Domain certificate"
}

variable "bucket_doamin_route53_zone_id" {
  type        = string
  description = "Domain's route 53 zone ID"
}

variable "bucket_path_config" {
  type = list(object({
    path             = string
    assume_role_name = string
    git_repository   = string
  }))
  description = "List of paths with GitHub and IAM assume role configuration"
}

variable "cloudfront_log_retention_days" {
  description = "Cloudfront log retention days"
  type        = number
  default     = 14
}
