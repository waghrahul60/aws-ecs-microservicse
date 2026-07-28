###############################################################################
# SECURITY GROUPS MODULE - variables.tf
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
  description = "VPC ID where security groups will be created"
  type        = string
}

variable "private_app_subnet_cidrs" {
  description = "CIDR blocks of private app subnets (used for VPC endpoint ingress)"
  type        = list(string)
}

variable "alb_ingress_cidr_blocks" {
  description = "Allowed CIDR blocks for ingress access to ALB. 0.0.0.0/0 and ::/0 are prohibited for security compliance."
  type        = list(string)
  default     = ["10.0.0.0/8"]

  validation {
    condition = alltrue([
      for cidr in var.alb_ingress_cidr_blocks : !contains(["0.0.0.0/0", "::/0"], cidr)
    ])
    error_message = "Security Policy Violation: Ingress from '0.0.0.0/0' or '::/0' is prohibited. Specify explicit CIDR blocks."
  }
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
