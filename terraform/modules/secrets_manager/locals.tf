###############################################################################
# SECRETS MANAGER MODULE - locals.tf
###############################################################################

locals {
  name_prefix            = "${var.project}-${var.environment}"
  is_prod                = var.environment == "prod"
  secret_recovery_window = local.is_prod ? 30 : 7
}
