###############################################################################
# ALB MODULE - locals.tf
###############################################################################

locals {
  name_prefix            = "${var.project}-${var.environment}"
  enable_deletion_protection = var.environment == "prod"
  access_logs_enabled    = var.access_log_bucket_id != ""
}
