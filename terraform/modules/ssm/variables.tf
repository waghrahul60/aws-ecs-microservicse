###############################################################################
# SSM MODULE - variables.tf
###############################################################################

variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "parameters" {
  description = "Map of SSM parameters to create. Key can be relative path (e.g. config/log_level) or absolute path (starting with /)."
  type = map(object({
    value       = string
    type        = optional(string, "String") # String | StringList | SecureString
    description = optional(string)
    sensitive   = optional(bool, false)
    tier        = optional(string, "Standard")
  }))
  default = {}
}

variable "kms_key_arn" {
  description = "KMS key ARN used for encrypting SecureString parameters"
  type        = string
  default     = null
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
