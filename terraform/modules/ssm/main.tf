###############################################################################
# SSM MODULE - main.tf
# Creates: SSM Parameter Store entries (String, StringList, SecureString)
#          for application configuration and environment variables
###############################################################################

locals {
  name_prefix = "${var.project}-${var.environment}"
}

# ─────────────────────────────────────────────
# SSM Parameters
# ─────────────────────────────────────────────
resource "aws_ssm_parameter" "this" {
  for_each = var.parameters

  name        = startswith(each.key, "/") ? each.key : "/${var.project}/${var.environment}/${each.key}"
  type        = lookup(each.value, "type", lookup(each.value, "sensitive", false) ? "SecureString" : "String")
  value       = each.value.value
  description = lookup(each.value, "description", "SSM Parameter for ${var.project} ${var.environment}")
  key_id      = (lookup(each.value, "type", "") == "SecureString" || lookup(each.value, "sensitive", false)) ? var.kms_key_arn : null
  tier        = lookup(each.value, "tier", "Standard")

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-${replace(trimprefix(each.key, "/"), "/", "-")}"
  })
}
