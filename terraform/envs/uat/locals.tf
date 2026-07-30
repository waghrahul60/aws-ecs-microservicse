###############################################################################
# UAT ENVIRONMENT - locals.tf
###############################################################################

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  project     = var.project
  environment = var.environment
  account_id  = data.aws_caller_identity.current.account_id
  name_prefix = "${var.project}-${var.environment}"

  common_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "Terraform"
    Owner       = "DevOps"
    CostCenter  = var.cost_center
  }
}
