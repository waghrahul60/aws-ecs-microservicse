###############################################################################
# SECRETS MANAGER MODULE - variables.tf
###############################################################################

variable "project" { type = string }
variable "environment" { type = string }

variable "db_username" {
  description = "Database master username"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Database master password"
  type        = string
  sensitive   = true
}

variable "db_host" {
  description = "Database host endpoint"
  type        = string
  default     = ""
}

variable "db_name" {
  description = "Database name"
  type        = string
}

variable "service_secrets" {
  description = "Map of service name to secret key-value pairs"
  type        = map(map(string))
  default     = {}
}

variable "enable_secret_rotation" {
  description = "Enable automatic rotation for DB credentials"
  type        = bool
  default     = false
}

variable "rotation_lambda_arn" {
  description = "Lambda function ARN for secret rotation"
  type        = string
  default     = ""
}

variable "rotation_days" {
  description = "Number of days between automatic rotations"
  type        = number
  default     = 30
}

variable "tags" {
  type    = map(string)
  default = {}
}
