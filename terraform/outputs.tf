output "default_bucket_name" {
  description = "The name of the S3 bucket for the main static site"
  value       = var.default_bucket_name
}

output "asset_bucket_name" {
  description = "The name of the existing S3 bucket for assets"
  value       = var.asset_bucket_name
}

output "cloudfront_distribution_domain" {
  description = "The CloudFront distribution domain name"
  value       = aws_cloudfront_distribution.cdn.domain_name
}

output "subdomain_url" {
  description = "The URL of the subdomain"
  value       = "https://${aws_route53_record.subdomain.name}"
}
