###############################################################################
# S3 MODULE - locals.tf
###############################################################################

locals {
  name_prefix            = "${var.project}-${var.environment}"
  frontend_bucket_name   = "${local.name_prefix}-frontend-${var.account_id}"
  access_log_bucket_name = "${local.name_prefix}-access-logs-${var.account_id}"
}
