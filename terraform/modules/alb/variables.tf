###############################################################################
# ALB MODULE - variables.tf
###############################################################################

variable "project" { type = string }
variable "environment" { type = string }

variable "alb_sg_id" {
  description = "ALB security group ID"
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for ALB"
  type        = list(string)
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN for HTTPS listener"
  type        = string
}

variable "frontend_target_group_arn" {
  description = "Target group ARN for the React frontend ECS service"
  type        = string
}

variable "service_a_target_group_arn" {
  description = "Target group ARN for Microservice A"
  type        = string
  default     = ""
}

variable "service_b_target_group_arn" {
  description = "Target group ARN for Microservice B"
  type        = string
  default     = ""
}

variable "service_c_target_group_arn" {
  description = "Target group ARN for Microservice C"
  type        = string
  default     = ""
}

variable "access_log_bucket_id" {
  description = "S3 bucket name for ALB access logs"
  type        = string
  default     = ""
}

variable "tags" {
  type    = map(string)
  default = {}
}
