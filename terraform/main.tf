provider "aws" {
  region = "ap-southeast-1"
}

# S3 Bucket for Static Website
resource "aws_s3_bucket" "static_site" {
  bucket = "idn-new-timmy-8"

  tags = {
    Name = "StaticSite"
  }
}

resource "aws_s3_bucket_acl" "static_site_acl" {
  bucket = aws_s3_bucket.static_site.id
  acl    = "public-read"
}

resource "aws_s3_bucket_website_configuration" "static_site_config" {
  bucket = aws_s3_bucket.static_site.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

# S3 Bucket for Broken Assets
resource "aws_s3_bucket" "broken_assets" {
  bucket = "bucket-new-timmy-idn"

  tags = {
    Name = "BrokenAssets"
  }
}

resource "aws_s3_bucket_acl" "broken_assets_acl" {
  bucket = aws_s3_bucket.broken_assets.id
  acl    = "public-read"
}

# ACM Certificate
resource "aws_acm_certificate" "cert" {
  domain_name       = "new-timmy-8.serverless.my.id"
  validation_method = "DNS"

  tags = {
    Name = "ACMCertificate"
  }
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "cdn" {
  origin {
    domain_name = aws_s3_bucket.static_site.bucket_regional_domain_name
    origin_id   = "S3-static-site"
  }

  origin {
    domain_name = aws_s3_bucket.broken_assets.bucket_regional_domain_name
    origin_id   = "S3-broken-assets"
  }

  enabled = true

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-static-site"
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  ordered_cache_behavior {
    path_pattern           = "/asset-img-broken.png"
    target_origin_id       = "S3-broken-assets"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD"]
    cached_methods  = ["GET", "HEAD"]

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate.cert.arn
    ssl_support_method   = "sni-only"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = {
    Name = "CloudFrontCDN"
  }
}

# Route 53 Record
resource "aws_route53_record" "subdomain" {
  zone_id = "ROUTE53_ZONE_ID" # Replace with your Route 53 zone ID
  name    = "new-timmy-8.serverless.my.id"
  type    = "CNAME"
  ttl     = 300
  records = [aws_cloudfront_distribution.cdn.domain_name]
}
