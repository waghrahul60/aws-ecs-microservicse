###############################################################################
# ECS MODULE - variables.tf
###############################################################################

variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for the Service Connect namespace"
  type        = string
}

variable "service_connect_namespace" {
  description = "DNS namespace for AWS Service Connect (e.g. app.internal)"
  type        = string
  default     = "app.internal"
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
