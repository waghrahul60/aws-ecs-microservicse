###############################################################################
# VPC MODULE - locals.tf
###############################################################################

locals {
  name_prefix  = "${var.project}-${var.environment}"
  nat_gw_count = var.single_nat_gateway ? 1 : length(var.availability_zones)
}
