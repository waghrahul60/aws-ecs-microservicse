###############################################################################
# RDS MODULE - locals.tf
###############################################################################

locals {
  name_prefix         = "${var.project}-${var.environment}"
  is_prod             = var.environment == "prod"
  skip_final_snapshot = !local.is_prod
  final_snapshot_id   = local.is_prod ? "${local.name_prefix}-final-snapshot" : null
  deletion_protection = local.is_prod
}
