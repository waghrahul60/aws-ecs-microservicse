###############################################################################
# ECR MODULE - variables.tf
###############################################################################

variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "service_names" {
  description = "List of microservice names to create ECR repositories for"
  type        = list(string)
  default     = ["frontend", "service-a", "service-b", "service-c"]
}

variable "image_tag_mutability" {
  description = "The tag mutability setting for the repository (MUTABLE | IMMUTABLE)"
  type        = string
  default     = "MUTABLE"
}

variable "scan_on_push" {
  description = "Indicates whether images are scanned after being pushed to the repository"
  type        = bool
  default     = true
}

variable "ecr_kms_key_arn" {
  description = "KMS key ARN for ECR image encryption (leave empty for default AWS managed key)"
  type        = string
  default     = ""
}

variable "max_tagged_image_count" {
  description = "Maximum number of tagged images to retain in ECR lifecycle policy"
  type        = number
  default     = 10
}

variable "untagged_image_retention_days" {
  description = "Days after which untagged images expire in ECR lifecycle policy"
  type        = number
  default     = 14
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
