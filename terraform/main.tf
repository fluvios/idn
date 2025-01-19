provider "aws" {
  region = "ap-southeast-1"
}

# Fetch the Route 53 hosted zone
data "aws_route53_zone" "zone" {
  name = "serverless.my.id."
}

# Reference the existing S3 bucket for assets
data "aws_s3_bucket" "asset_bucket" {
  bucket = "bucket-new-timmy-idn"
}

# Create a new S3 bucket for the main static site
resource "aws_s3_bucket" "default_site" {
  bucket = "idn-new-timmy-8"
  force_destroy = true
  tags = {
    Name = "DefaultSiteBucket"
  }
}

# Add website configuration to the S3 bucket
resource "aws_s3_bucket_website_configuration" "default_site" {
  bucket = aws_s3_bucket.default_site.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

# Configure public access block for the bucket
resource "aws_s3_bucket_public_access_block" "public_access_block" {
  bucket                  = aws_s3_bucket.default_site.id
  block_public_acls       = false
  ignore_public_acls      = false
  block_public_policy     = false
  restrict_public_buckets = false
}

# Add a bucket policy to allow CloudFront access
resource "aws_s3_bucket_policy" "default_site_policy" {
  bucket = aws_s3_bucket.default_site.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontAccess"
        Effect    = "Allow"
        Principal = {
          AWS = "arn:aws:iam::cloudfront:user/CloudFront Origin Access Identity ${aws_cloudfront_origin_access_identity.oai.id}"
        }
        Action   = "s3:GetObject"
        Resource = "arn:aws:s3:::${aws_s3_bucket.default_site.id}/*"
      }
    ]
  })
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "cdn" {
  enabled = true
  default_root_object = "index.html"

  # Default origin: S3 bucket for main site
  origin {
    domain_name = aws_s3_bucket.default_site.bucket_regional_domain_name
    origin_id   = "idn-new-timmy-8"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
    }
  }

  # Additional origin: Existing S3 bucket for assets
  origin {
    domain_name = data.aws_s3_bucket.asset_bucket.bucket_regional_domain_name
    origin_id   = "bucket-new-timmy-idn"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
    }
  }

  # Default behavior for main site
  default_cache_behavior {
    target_origin_id       = "idn-new-timmy-8"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  # Behavior for asset-img-broken.png
  ordered_cache_behavior {
    path_pattern           = "/asset-img-broken.png"
    target_origin_id       = "bucket-new-timmy-idn"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  # Specify custom domain in aliases
  aliases = ["new-timmy-8.serverless.my.id"]  

  # SSL settings for HTTPS
  viewer_certificate {
    acm_certificate_arn = "arn:aws:acm:us-east-1:166190020492:certificate/1119d63b-db83-4afb-b726-4a8944f6ec7f"
    ssl_support_method = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = {
    Name = "CloudFrontDistribution"
  }
}

# Route 53 Record for the Subdomain
resource "aws_route53_record" "subdomain" {
  zone_id = data.aws_route53_zone.zone.zone_id
  name    = "new-timmy-8.serverless.my.id"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.cdn.domain_name
    zone_id                = aws_cloudfront_distribution.cdn.hosted_zone_id
    evaluate_target_health = false
  }
}

# CloudFront Origin Access Identity
resource "aws_cloudfront_origin_access_identity" "oai" {
  comment = "OAI for CloudFront"
}
