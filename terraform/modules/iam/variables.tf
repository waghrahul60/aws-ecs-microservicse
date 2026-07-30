###############################################################################
# IAM MODULE - variables.tf
###############################################################################

variable "project" { type = string }
variable "environment" { type = string }

variable "secrets_manager_arns" {
  description = "List of Secrets Manager secret ARNs the ECS roles can access"
  type        = list(string)
  default     = ["*"]
}

variable "ssm_parameter_arns" {
  description = "List of SSM Parameter ARNs the ECS roles can access"
  type        = list(string)
  default     = ["*"]
}

variable "kms_key_arns" {
  description = "KMS key ARNs for decrypt permissions"
  type        = list(string)
  default     = ["*"]
}

variable "tags" {
  type    = map(string)
  default = {}
}
