###############################################################################
# CLOUDFRONT MODULE - locals.tf
###############################################################################

locals {
  name_prefix   = "${var.project}-${var.environment}"
  alb_enabled   = var.alb_dns_name != ""
  s3_origin_id  = "S3-${var.project}-${var.environment}-frontend"
  alb_origin_id = "ALB-${var.project}-${var.environment}-api"
}
