###############################################################################
# RDS MODULE - variables.tf
###############################################################################

variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "private_data_subnet_ids" {
  description = "Private data-tier subnet IDs"
  type        = list(string)
}

variable "rds_sg_id" {
  description = "Security group ID for RDS"
  type        = string
}

variable "postgres_major_version" {
  description = "PostgreSQL major version for parameter group family (e.g. 16)"
  type        = string
  default     = "16"
}

variable "postgres_engine_version" {
  description = "Full PostgreSQL engine version string (e.g. 16.2)"
  type        = string
  default     = "16.2"
}

variable "db_instance_class" {
  description = "RDS instance type"
  type        = string
  default     = "db.t3.medium"
}

variable "allocated_storage" {
  description = "Initial allocated storage in GiB"
  type        = number
  default     = 100
}

variable "max_allocated_storage" {
  description = "Maximum storage for autoscaling in GiB"
  type        = number
  default     = 500
}

variable "db_name" {
  description = "Initial database name"
  type        = string
}

variable "db_username" {
  description = "Master DB username"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Master DB password"
  type        = string
  sensitive   = true
}

variable "multi_az" {
  description = "Enable Multi-AZ deployment"
  type        = bool
  default     = true
}

variable "backup_retention_period" {
  description = "Number of days to retain automated backups"
  type        = number
  default     = 7
}

variable "alarm_sns_topic_arn" {
  description = "SNS topic ARN for RDS CloudWatch alarms"
  type        = string
  default     = ""
}

variable "tags" {
  type    = map(string)
  default = {}
}
