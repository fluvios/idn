output "s3_static_bucket" {
  value = aws_s3_bucket.static_site.bucket
}

output "cloudfront_distribution" {
  value = aws_cloudfront_distribution.cdn.domain_name
}
