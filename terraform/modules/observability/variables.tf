###############################################################################
# OBSERVABILITY MODULE - variables.tf
###############################################################################

variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "aws_region" {
  description = "Primary AWS region"
  type        = string
}

variable "ecs_cluster_name" {
  description = "ECS cluster name"
  type        = string
  default     = ""
}

variable "alb_arn_suffix" {
  description = "ALB ARN suffix (e.g. app/myapp-dev-alb/1234567890) for CloudWatch metrics"
  type        = string
  default     = ""
}

variable "db_instance_id" {
  description = "RDS DB Instance identifier"
  type        = string
  default     = ""
}

variable "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  type        = string
  default     = ""
}

variable "alarm_email" {
  description = "Email address to receive infrastructure SNS alarm notifications"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
