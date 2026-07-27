###############################################################################
# WAF MODULE - outputs.tf
###############################################################################

output "web_acl_arn" {
  description = "ARN of the WAF Web ACL (passed to CloudFront)"
  value       = aws_wafv2_web_acl.this.arn
}

output "web_acl_id" {
  description = "ID of the WAF Web ACL"
  value       = aws_wafv2_web_acl.this.id
}

output "web_acl_capacity" {
  description = "Capacity consumed by the WAF Web ACL rules"
  value       = aws_wafv2_web_acl.this.capacity
}
