###############################################################################
# STAGING ENVIRONMENT - variables.tf
###############################################################################

variable "project" {
  description = "Project name"
  type        = string
  default     = "myapp"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "staging"
}

variable "aws_region" {
  description = "Primary AWS region"
  type        = string
  default     = "us-east-1"
}

variable "cost_center" {
  description = "Cost center tag"
  type        = string
  default     = "engineering"
}

# ── Network ──
variable "vpc_cidr" {
  type    = string
  default = "10.20.0.0/16"
}

variable "availability_zones" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.20.1.0/24", "10.20.2.0/24"]
}

variable "private_app_subnet_cidrs" {
  type    = list(string)
  default = ["10.20.10.0/24", "10.20.11.0/24"]
}

variable "private_data_subnet_cidrs" {
  type    = list(string)
  default = ["10.20.20.0/24", "10.20.21.0/24"]
}

# ── DNS & TLS ──
variable "domain_aliases" {
  type    = list(string)
  default = ["staging.myapp.example.com"]
}

variable "cloudfront_acm_certificate_arn" {
  description = "ACM cert ARN in us-east-1 for CloudFront"
  type        = string
}

variable "alb_acm_certificate_arn" {
  description = "ACM cert ARN in the primary region for ALB"
  type        = string
}

variable "alb_custom_header_value" {
  description = "Secret header value for ALB origin validation"
  type        = string
  sensitive   = true
}

# ── Database ──
variable "db_name" {
  type    = string
  default = "appdb"
}

variable "db_username" {
  type      = string
  sensitive = true
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "db_instance_class" {
  type    = string
  default = "db.t3.medium"
}

# ── Image Tags ──
variable "frontend_image_tag" {
  type    = string
  default = "latest"
}

variable "service_a_image_tag" {
  type    = string
  default = "latest"
}

variable "service_b_image_tag" {
  type    = string
  default = "latest"
}

variable "service_c_image_tag" {
  type    = string
  default = "latest"
}

# ── Service API Keys ──
variable "service_a_api_key" {
  type      = string
  sensitive = true
}

variable "service_b_api_key" {
  type      = string
  sensitive = true
}

variable "service_c_api_key" {
  type      = string
  sensitive = true
}
