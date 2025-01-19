provider "aws" {
  region = "ap-southeast-1"
}

# S3 Bucket for Static Website
resource "aws_s3_bucket" "static_site" {
  bucket = "idn-new-timmy-8"

  tags = {
    Name = "StaticSiteBucket"
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

resource "aws_s3_bucket_policy" "static_site_policy" {
  bucket = aws_s3_bucket.static_site.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "PublicReadGetObject",
        Effect    = "Allow",
        Principal = "*",
        Action    = "s3:GetObject",
        Resource  = "${aws_s3_bucket.static_site.arn}/*"
      }
    ]
  })
}

# Use the ACM Certificate directly
viewer_certificate {
  acm_certificate_arn = "arn:aws:acm:us-east-1:166190020492:certificate/1119d63b-db83-4afb-b726-4a8944f6ec7f"
  ssl_support_method   = "sni-only"
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "cdn" {
  origin {
    domain_name = aws_s3_bucket.static_site.bucket_regional_domain_name
    origin_id   = "S3Origin"
  }

  enabled = true

  default_cache_behavior {
    target_origin_id       = "S3Origin"
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

  viewer_certificate {
    acm_certificate_arn = "arn:aws:acm:us-east-1:166190020492:certificate/1119d63b-db83-4afb-b726-4a8944f6ec7f"
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

# Route 53 DNS Record
data "aws_route53_zone" "zone" {
  name = "serverless.my.id."
}

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
