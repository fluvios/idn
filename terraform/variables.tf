variable "default_bucket_name" {
  description = "The name of the default S3 bucket for the static site"
  default     = "idn-new-timmy-x"
}

variable "asset_bucket_name" {
  description = "The name of the existing S3 bucket for assets"
  default     = "bucket-new-timmy-idn"
}

variable "subdomain" {
  description = "The subdomain for the static site"
  default     = "new-timmy-x.serverless.my.id"
}

variable "region" {
  description = "AWS region"
  default     = "ap-southeast-1"
}
