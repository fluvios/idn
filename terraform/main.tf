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
  tags = {
    Name = "DefaultSiteBucket"
  }
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "cdn" {
  enabled = true

  # Default origin: S3 bucket for main site
  origin {
    domain_name = aws_s3_bucket.default_site.bucket_regional_domain_name
    origin_id   = "DefaultS3Origin"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
    }
  }

  # Additional origin: Existing S3 bucket for assets
  origin {
    domain_name = data.aws_s3_bucket.asset_bucket.bucket_regional_domain_name
    origin_id   = "AssetS3Origin"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
    }
  }

  # Default behavior for main site
  default_cache_behavior {
    target_origin_id       = "DefaultS3Origin"
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
    target_origin_id       = "AssetS3Origin"
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

  # SSL settings for HTTPS
  viewer_certificate {
    acm_certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/1119d63b-db83-4a8944f6ec7f"
    ssl_support_method   = "sni-only"
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

resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name  = dvo.resource_record_name
      type  = dvo.resource_record_type
      value = dvo.resource_record_value
    }
  }

  zone_id = data.aws_route53_zone.zone.zone_id

  name  = each.value.name
  type  = each.value.type
  ttl   = 60
  records = [
    each.value.value,
  ]
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
