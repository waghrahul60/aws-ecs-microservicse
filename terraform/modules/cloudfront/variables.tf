###############################################################################
# CLOUDFRONT MODULE - variables.tf
###############################################################################

variable "project" { type = string }
variable "environment" { type = string }

variable "s3_bucket_regional_domain_name" {
  description = "S3 bucket regional domain name for the React frontend"
  type        = string
}

variable "alb_dns_name" {
  description = "ALB DNS name for API origin (leave empty to disable)"
  type        = string
  default     = ""
}

variable "alb_custom_header_value" {
  description = "Secret value for the X-Custom-Header sent to ALB (WAF validation)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "waf_web_acl_arn" {
  description = "WAF Web ACL ARN (must be in us-east-1 for CloudFront)"
  type        = string
  default     = ""
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN (must be in us-east-1 for CloudFront)"
  type        = string
}

variable "domain_aliases" {
  description = "Custom domain aliases for the CloudFront distribution"
  type        = list(string)
  default     = []
}

variable "price_class" {
  description = "CloudFront price class"
  type        = string
  default     = "PriceClass_100"
}

variable "geo_restriction_type" {
  description = "Type of geo restriction (none | whitelist | blacklist)"
  type        = string
  default     = "none"
}

variable "geo_restriction_locations" {
  description = "Country codes for geo restriction"
  type        = list(string)
  default     = []
}

variable "access_log_bucket_domain_name" {
  description = "S3 bucket domain for CloudFront access logs"
  type        = string
  default     = ""
}

variable "tags" {
  type    = map(string)
  default = {}
}
