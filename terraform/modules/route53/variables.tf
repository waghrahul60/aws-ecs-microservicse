###############################################################################
# ROUTE53 MODULE - variables.tf
###############################################################################

variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "domain_name" {
  description = "Primary domain name for Route 53 zone (e.g. example.com)"
  type        = string
}

variable "create_zone" {
  description = "Create a new Route 53 public zone if true, else lookup existing zone"
  type        = bool
  default     = false
}

variable "domain_aliases" {
  description = "List of domain aliases to route to CloudFront (e.g. ['staging.myapp.example.com'])"
  type        = list(string)
  default     = []
}

variable "cloudfront_domain_name" {
  description = "CloudFront distribution domain name (e.g. d1234.cloudfront.net)"
  type        = string
  default     = ""
}

variable "cloudfront_hosted_zone_id" {
  description = "CloudFront canonical hosted zone ID (always Z2FDTNDATAQYW2)"
  type        = string
  default     = "Z2FDTNDATAQYW2"
}

variable "alb_dns_name" {
  description = "ALB DNS name for direct ALB record"
  type        = string
  default     = ""
}

variable "alb_hosted_zone_id" {
  description = "ALB hosted zone ID for alias record"
  type        = string
  default     = ""
}

variable "alb_domain_name" {
  description = "Custom domain name for ALB direct record (e.g. alb.staging.myapp.example.com)"
  type        = string
  default     = ""
}

variable "create_acm_certificate" {
  description = "Request and validate an ACM Certificate via Route 53 DNS"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
