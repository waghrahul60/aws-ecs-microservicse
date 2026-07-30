###############################################################################
# ROUTE53 MODULE - outputs.tf
###############################################################################

output "zone_id" {
  description = "Route 53 hosted zone ID"
  value       = local.zone_id
}

output "zone_name" {
  description = "Route 53 hosted zone name"
  value       = var.domain_name
}

output "name_servers" {
  description = "Route 53 hosted zone name servers"
  value       = var.create_zone ? aws_route53_zone.this[0].name_servers : data.aws_route53_zone.this[0].name_servers
}

output "acm_certificate_arn" {
  description = "Validated ACM certificate ARN (if create_acm_certificate = true)"
  value       = var.create_acm_certificate ? aws_acm_certificate_validation.this[0].certificate_arn : null
}
