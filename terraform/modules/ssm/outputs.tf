###############################################################################
# SSM MODULE - outputs.tf
###############################################################################

output "parameter_arns" {
  description = "Map of parameter key to SSM parameter ARN"
  value       = { for k, v in aws_ssm_parameter.this : k => v.arn }
}

output "parameter_names" {
  description = "Map of parameter key to SSM parameter full path name"
  value       = { for k, v in aws_ssm_parameter.this : k => v.name }
}

output "parameter_types" {
  description = "Map of parameter key to parameter type"
  value       = { for k, v in aws_ssm_parameter.this : k => v.type }
}

output "all_parameter_arns" {
  description = "List of all SSM parameter ARNs"
  value       = [for v in aws_ssm_parameter.this : v.arn]
}
