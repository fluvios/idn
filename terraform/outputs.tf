output "s3_bucket_name" {
  description = "The name of the S3 bucket for static site hosting"
  value       = aws_s3_bucket.static_site.id
}

output "cloudfront_distribution_id" {
  description = "The ID of the CloudFront distribution"
  value       = aws_cloudfront_distribution.cdn.id
}

output "cloudfront_domain_name" {
  description = "The domain name of the CloudFront distribution"
  value       = aws_cloudfront_distribution.cdn.domain_name
}

output "route53_record" {
  description = "The Route 53 record for the subdomain"
  value       = aws_route53_record.subdomain.name
}
