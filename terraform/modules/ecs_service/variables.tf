###############################################################################
# ECS SERVICES MODULE - variables.tf
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
  description = "AWS region"
  type        = string
}

variable "service_name" {
  description = "Short name of the ECS service (e.g. frontend, service-a)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "ecs_cluster_arn" {
  description = "ECS Cluster ARN"
  type        = string
}

variable "ecs_cluster_name" {
  description = "ECS Cluster name"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for ECS tasks"
  type        = list(string)
}

variable "ecs_tasks_sg_id" {
  description = "Security group ID for ECS tasks"
  type        = string
}

variable "ecr_repository_url" {
  description = "ECR repository URL for the service image"
  type        = string
}

variable "image_tag" {
  description = "Docker image tag to deploy"
  type        = string
  default     = "latest"
}

variable "container_port" {
  description = "Port the container listens on"
  type        = number
}

variable "app_protocol" {
  description = "Application protocol for Service Connect (http | http2 | grpc)"
  type        = string
  default     = "http"
}

variable "task_cpu" {
  description = "Fargate task CPU units"
  type        = number
  default     = 512
}

variable "task_memory" {
  description = "Fargate task memory in MiB"
  type        = number
  default     = 1024
}

variable "execution_role_arn" {
  description = "ECS task execution IAM role ARN"
  type        = string
}

variable "task_role_arn" {
  description = "ECS task IAM role ARN"
  type        = string
}

variable "service_connect_namespace_arn" {
  description = "ARN of the Service Connect namespace (app.internal)"
  type        = string
}

variable "service_connect_port_name" {
  description = "Port name for Service Connect discovery (set to service_name)"
  type        = string
  default     = null
}

variable "create_target_group" {
  description = "Whether to create an ALB target group (false for internal-only services)"
  type        = bool
  default     = true
}

variable "health_check_path" {
  description = "ALB health check path"
  type        = string
  default     = "/health"
}

variable "health_check" {
  description = "Container health check configuration"
  type = object({
    command      = list(string)
    interval     = number
    timeout      = number
    retries      = number
    start_period = number
  })
  default = null
}

variable "desired_count" {
  description = "Desired number of ECS tasks"
  type        = number
  default     = 2
}

variable "min_capacity" {
  description = "Minimum number of tasks for auto scaling"
  type        = number
  default     = 2
}

variable "max_capacity" {
  description = "Maximum number of tasks for auto scaling"
  type        = number
  default     = 10
}

variable "cpu_scaling_target" {
  description = "Target CPU % for auto scaling"
  type        = number
  default     = 60
}

variable "memory_scaling_target" {
  description = "Target memory % for auto scaling"
  type        = number
  default     = 70
}

variable "environment_variables" {
  description = "Environment variables for the container"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "secrets" {
  description = "Secrets from Secrets Manager or SSM to inject as environment variables"
  type = list(object({
    name       = string
    value_from = string
  }))
  default = []
}

variable "log_retention_days" {
  description = "CloudWatch log retention"
  type        = number
  default     = 30
}

variable "enable_execute_command" {
  description = "Enable ECS Exec for debugging"
  type        = bool
  default     = false
}

variable "alarm_sns_topic_arn" {
  description = "SNS topic ARN for CloudWatch alarm notifications"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
