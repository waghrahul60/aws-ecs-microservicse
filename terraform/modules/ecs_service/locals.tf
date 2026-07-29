###############################################################################
# ECS SERVICE MODULE - locals.tf
###############################################################################

locals {
  name_prefix = "${var.project}-${var.environment}-${var.service_name}"
  log_group   = "/ecs/${var.project}-${var.environment}/${var.service_name}"
}
