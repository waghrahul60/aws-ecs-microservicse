###############################################################################
# WAF MODULE - variables.tf
###############################################################################

variable "project" { type = string }
variable "environment" { type = string }

variable "rate_limit_per_ip" {
  description = "Maximum requests per 5-minute window per IP before blocking"
  type        = number
  default     = 2000
}

variable "waf_log_destination_arn" {
  description = "ARN of the log destination (Kinesis Firehose or CloudWatch Logs)"
  type        = string
  default     = ""
}

variable "tags" {
  type    = map(string)
  default = {}
}
