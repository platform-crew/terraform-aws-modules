############################################################
# Static Files S3 Bucket
############################################################

# Primary S3 bucket to store static files (served via CloudFront)
# Note: CloudFront logging is already enabled, so no S3 access logging here.
# trivy:ignore:AVD-AWS-0089
resource "aws_s3_bucket" "static_files" {
  bucket = var.bucket_name

  tags = {
    Name        = var.bucket_name
    Environment = var.environment
  }
}

# Enable S3 bucket versioning for object history and rollback
resource "aws_s3_bucket_versioning" "static_files_versioning" {
  bucket = aws_s3_bucket.static_files.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Block all forms of public access to enforce least-privilege access
resource "aws_s3_bucket_public_access_block" "static_files_access_block" {
  bucket = aws_s3_bucket.static_files.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# KMS CMK (Customer-Managed Key) for encrypting S3 bucket objects
resource "aws_kms_key" "staticfiles_kms_key" {
  description         = "KMS CMK for static files bucket"
  enable_key_rotation = true

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      # Default AWS account root user gets full access
      {
        Sid    = "EnableIAMUserPermissions",
        Effect = "Allow",
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        Action   = "kms:*",
        Resource = "*"
      },
      # Allow GitHub Actions role(s) to use the key for S3 object encryption
      {
        Sid    = "AllowGitHubActionsUseOfKey",
        Effect = "Allow",
        Principal = {
          AWS = [
            for cfg in var.bucket_path_config :
            aws_iam_role.github_actions_s3_upload[cfg.path].arn
          ]
        },
        Action = [
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:GenerateDataKey"
        ],
        Resource = "*"
      },
      # CloudFront service principal
      {
        Sid    = "AllowCloudFrontService"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = ["kms:Decrypt"]
        Resource = "*"
      }
    ]
  })
}

# Enforce server-side encryption using KMS for all objects
resource "aws_s3_bucket_server_side_encryption_configuration" "static_files" {
  bucket = aws_s3_bucket.static_files.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.staticfiles_kms_key.arn
    }
  }
}


############################################################
# IAM Roles & Policies (GitHub Actions)
############################################################

# IAM roles for GitHub Actions OIDC to upload/delete static files to S3
resource "aws_iam_role" "github_actions_s3_upload" {
  for_each = {
    for cfg in var.bucket_path_config : cfg.path => cfg
  }

  name               = each.value.assume_role_name
  assume_role_policy = data.aws_iam_policy_document.github_oidc_trust[each.key].json

  tags = {
    Name        = each.value.assume_role_name
    Environment = var.environment
  }
}

# IAM inline policies granting limited S3 access per path prefix
resource "aws_iam_role_policy" "s3_upload_policy" {
  for_each = {
    for cfg in var.bucket_path_config : cfg.path => cfg
  }

  name = "${each.key}-s3-upload-policy"
  role = aws_iam_role.github_actions_s3_upload[each.key].id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      # Upload, delete, and object existence checks (scoped to prefix)
      {
        Sid      = "AllowUploadAndDeleteToPathPrefix",
        Effect   = "Allow",
        Action   = ["s3:PutObject", "s3:DeleteObject", "s3:HeadObject"],
        Resource = "${aws_s3_bucket.static_files.arn}/${each.key}/*"
      },
      # Allow list bucket but only within the given prefix
      {
        Sid      = "AllowScopedListBucket",
        Effect   = "Allow",
        Action   = "s3:ListBucket",
        Resource = aws_s3_bucket.static_files.arn,
        Condition = {
          StringLike = {
            "s3:prefix" = "${each.key}/*"
          }
        }
      }
    ]
  })
}


############################################################
# CloudFront + WAF
############################################################

# Web Application Firewall (WAF) to protect CloudFront distribution
resource "aws_wafv2_web_acl" "static_site" {
  provider    = aws.us_east_1
  name        = "${var.environment}-static-site-waf"
  description = "WAF for static site CloudFront distribution"
  scope       = "CLOUDFRONT"

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "staticSiteWAF"
    sampled_requests_enabled   = true
  }

  ## Rate limitting
  rule {
    name     = "RateLimitting"
    priority = 1

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = var.cdn_waf_rate_limitting
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateLimitting"
      sampled_requests_enabled   = true # set true to see sample blocked requests
    }
  }

  ## SQL Injection Rule
  rule {
    name     = "BlockSQLInjection"
    priority = 2
    action {
      block {}
    }
    statement {
      sqli_match_statement {
        field_to_match {
          all_query_arguments {}
        }
        text_transformation {
          priority = 0
          type     = "URL_DECODE"
        }
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "BlockSQLInjection"
      sampled_requests_enabled   = true
    }
  }

  ## XSS Rule
  rule {
    name     = "BlockXSS"
    priority = 3
    action {
      block {}
    }
    statement {
      xss_match_statement {
        field_to_match {
          all_query_arguments {}
        }
        text_transformation {
          priority = 0
          type     = "HTML_ENTITY_DECODE"
        }
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "BlockXSS"
      sampled_requests_enabled   = true
    }
  }

  ## Block Bad Bots (User-Agent header match)
  rule {
    name     = "BlockBadBots"
    priority = 4
    action {
      block {}
    }

    statement {
      or_statement {
        dynamic "statement" {
          for_each = var.cdn_waf_bad_bots
          content {
            byte_match_statement {
              search_string         = statement.value
              positional_constraint = "CONTAINS"

              field_to_match {
                headers {
                  match_scope       = "VALUE"
                  oversize_handling = "MATCH"
                  match_pattern {
                    included_headers = ["User-Agent"]
                  }
                }
              }

              text_transformation {
                priority = 0
                type     = "NONE"
              }
            }
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "BlockBadBots"
      sampled_requests_enabled   = true
    }
  }
}

# Origin Access Control to securely connect CloudFront with S3
resource "aws_cloudfront_origin_access_control" "s3_oac" {
  name                              = "s3-oac"
  description                       = "CloudFront access control for S3"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# CloudFront Distribution to serve S3 content securely via HTTPS
# We should use an external platform for observability, and since this distribution serves only static files,
# enabling logging would unnecessarily increase costs.
#trivy:ignore:AVD-AWS-0010 CloudFront logging is intentionally disabled.
resource "aws_cloudfront_distribution" "cdn" {
  enabled     = true
  price_class = "PriceClass_100" # Cheapest tier (US, Canada, Europe)
  aliases     = [var.bucket_domain_name]
  web_acl_id  = aws_wafv2_web_acl.static_site.arn

  origin {
    domain_name              = aws_s3_bucket.static_files.bucket_regional_domain_name
    origin_id                = var.bucket_name
    origin_access_control_id = aws_cloudfront_origin_access_control.s3_oac.id
  }

  default_cache_behavior {
    target_origin_id       = var.bucket_name
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD"]

    forwarded_values {
      query_string = false
      cookies { forward = "none" }
    }

    min_ttl     = var.cdn_cache_min_ttl
    default_ttl = var.cdn_cache_default_ttl
    max_ttl     = var.cdn_cache_max_ttl
  }

  restrictions {
    geo_restriction { restriction_type = "none" }
  }

  viewer_certificate {
    acm_certificate_arn      = var.bucket_domain_cert_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}


############################################################
# Route 53 (DNS Alias for CloudFront)
############################################################
resource "aws_route53_record" "cdn_alias" {
  zone_id = var.bucket_domain_route53_zone_id
  name    = var.bucket_domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.cdn.domain_name
    zone_id                = aws_cloudfront_distribution.cdn.hosted_zone_id
    evaluate_target_health = false
  }
}


############################################################
# S3 Bucket Policy (Restrict Access)
############################################################

# Bucket policy to allow:
# - CloudFront to GET objects
# - GitHub Actions to upload/delete within specific prefixes
resource "aws_s3_bucket_policy" "idp_static_file_bucket_policy" {
  bucket = aws_s3_bucket.static_files.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = flatten([
      for cfg in var.bucket_path_config : [
        # Allow CloudFront distribution to read objects
        {
          Sid       = "AllowCloudFrontGet-${cfg.path}",
          Effect    = "Allow",
          Principal = { Service = "cloudfront.amazonaws.com" },
          Action    = "s3:GetObject",
          Resource  = "${aws_s3_bucket.static_files.arn}/${cfg.path}/*",
          Condition = {
            StringEquals = {
              "AWS:SourceArn" = "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/${aws_cloudfront_distribution.cdn.id}"
            }
          }
        },
        # Allow GitHub Actions role to upload/delete objects
        {
          Sid       = "AllowGitHubUploadAndGet-${cfg.path}",
          Effect    = "Allow",
          Principal = { AWS = aws_iam_role.github_actions_s3_upload[cfg.path].arn },
          Action    = ["s3:PutObject", "s3:DeleteObject", "s3:GetObject"],
          Resource  = "${aws_s3_bucket.static_files.arn}/${cfg.path}/*"
        },
        # Allow GitHub Actions role to list within specific prefixes
        {
          Sid       = "AllowGitHubListBucket-${cfg.path}",
          Effect    = "Allow",
          Principal = { AWS = aws_iam_role.github_actions_s3_upload[cfg.path].arn },
          Action    = "s3:ListBucket",
          Resource  = aws_s3_bucket.static_files.arn,
          Condition = {
            StringLike = {
              "s3:prefix" = "${cfg.path}/*"
            }
          }
        }
      ]
    ])
  })
}
