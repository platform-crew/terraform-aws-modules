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

variable "bucket_domain_route53_zone_id" {
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

variable "cdn_waf_rate_limitting" {
  description = "Rate limitting for S3 bucket access from cloudfront by IP."
  type        = number
  default     = 20000 # safe for S3 static files
}

variable "cdn_waf_bad_bots" {
  type        = list(string)
  description = "List of bad bot User-Agent substrings to block"
  default     = ["BadBot", "EvilScraper"]
}

variable "cdn_cache_min_ttl" {
  description = "Minimum TTL for CDN cache"
  type        = number
  default     = 0
}

variable "cdn_cache_default_ttl" {
  description = "Default TTL for CDN cache"
  type        = number
  default     = 21600 # 6 hours
}

variable "cdn_cache_max_ttl" {
  description = "Maximum TTL for CDN cache"
  type        = number
  default     = 86400 # 1 day
}
