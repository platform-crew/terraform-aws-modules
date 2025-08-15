#####################
# S3 Bucket
#####################
resource "aws_s3_bucket" "static_files" {
  bucket = var.bucket_name

  tags = {
    Name        = var.bucket_name
    Environment = var.environment
  }
}

resource "aws_s3_bucket_versioning" "static_files_versioning" {
  bucket = aws_s3_bucket.static_files.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "access_block" {
  bucket = aws_s3_bucket.static_files.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

#####################
# IAM Roles & Policies
#####################
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

resource "aws_iam_role_policy" "s3_upload_policy" {
  for_each = {
    for cfg in var.bucket_path_config : cfg.path => cfg
  }

  name = "${each.key}-s3-upload-policy"
  role = aws_iam_role.github_actions_s3_upload[each.key].id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid      = "AllowUploadAndDeleteToPathPrefix",
        Effect   = "Allow",
        Action   = ["s3:PutObject", "s3:DeleteObject", "s3:HeadObject"],
        Resource = "${aws_s3_bucket.static_files.arn}/${each.key}/*"
      },
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

#####################
# CloudFront
#####################

# Origin Access control
resource "aws_cloudfront_origin_access_control" "s3_oac" {
  name                              = "s3-oac"
  description                       = "CloudFront access control for S3"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "cdn" {
  enabled     = true
  price_class = "PriceClass_100"
  aliases     = [var.bucket_domain_name]

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
      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 3600
    max_ttl     = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = var.bucket_domain_cert_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}

#####################
# Route53
#####################
resource "aws_route53_record" "cdn_alias" {
  zone_id = var.bucket_doamin_route53_zone_id
  name    = var.bucket_domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.cdn.domain_name
    zone_id                = aws_cloudfront_distribution.cdn.hosted_zone_id
    evaluate_target_health = false
  }
}

#####################
# S3 Bucket Policy
#####################
resource "aws_s3_bucket_policy" "idp_static_file_bucket_policy" {
  bucket = aws_s3_bucket.static_files.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = flatten([
      for cfg in var.bucket_path_config : [
        {
          Sid    = "AllowCloudFrontGet-${cfg.path}",
          Effect = "Allow",
          Principal = {
            Service = "cloudfront.amazonaws.com"
          },
          Action   = "s3:GetObject",
          Resource = "${aws_s3_bucket.static_files.arn}/${cfg.path}/*"
          Condition = {
            StringEquals = {
              "AWS:SourceArn" = "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/${aws_cloudfront_distribution.cdn.id}"
            }
          }
        },
        {
          Sid    = "AllowGitHubUploadAndGet-${cfg.path}",
          Effect = "Allow",
          Principal = {
            AWS = aws_iam_role.github_actions_s3_upload[cfg.path].arn
          },
          Action   = ["s3:PutObject", "s3:DeleteObject", "s3:GetObject"],
          Resource = "${aws_s3_bucket.static_files.arn}/${cfg.path}/*"
        },
        {
          Sid    = "AllowGitHubListBucket-${cfg.path}",
          Effect = "Allow",
          Principal = {
            AWS = aws_iam_role.github_actions_s3_upload[cfg.path].arn
          },
          Action   = "s3:ListBucket",
          Resource = aws_s3_bucket.static_files.arn,
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
