variable "aws_region" {
  default = "ap-southeast-1"
}

variable "bucket_static" {
  default = "idn-new-timmy-8"
}

variable "bucket_assets" {
  default = "bucket-new-timmy-idn"
}

variable "domain_name" {
  default = "new-timmy-8.serverless.my.id"
}

variable "route53_zone_id" {
  description = "The Route 53 hosted zone ID for your domain"
  type        = string
}