###############################################################################
# S3 MODULE - variables.tf
###############################################################################

variable "project" { type = string }
variable "environment" { type = string }

variable "account_id" {
  description = "AWS account ID (used to ensure globally unique bucket names)"
  type        = string
}

variable "cloudfront_distribution_arn" {
  description = "CloudFront distribution ARN for bucket policy OAC condition"
  type        = string
}

variable "create_access_log_bucket" {
  description = "Whether to create the access logs bucket"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "Days to retain access logs before expiration"
  type        = number
  default     = 90
}

variable "tags" {
  type    = map(string)
  default = {}
}
