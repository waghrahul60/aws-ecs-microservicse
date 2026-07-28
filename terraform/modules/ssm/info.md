# Module: `ssm`

> Creates AWS SSM Parameter Store parameters (`String`, `StringList`, `SecureString`) for centralized application configuration, environment settings, and encrypted configuration parameters.

---

## Usage

```hcl
module "ssm" {
  source = "../../modules/ssm"

  project     = var.project
  environment = var.environment

  kms_key_arn = module.secrets_manager.kms_key_arn # Optional KMS key for SecureString parameters

  parameters = {
    "config/aws_region" = {
      value       = var.aws_region
      description = "AWS region"
      sensitive   = false
    }
    "config/log_level" = {
      value       = "INFO"
      description = "Application log level"
      sensitive   = false
    }
    "config/service_connect_namespace" = {
      value       = "app.internal"
      description = "Service Connect internal namespace"
      sensitive   = false
    }
  }

  tags = local.common_tags
}
```

---

## Input Variables

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `project` | `string` | ✅ | — | Project name |
| `environment` | `string` | ✅ | — | Environment name |
| `parameters` | `map(object)` | | `{}` | Map of parameters to create (`value`, `type`, `description`, `sensitive`, `tier`) |
| `kms_key_arn` | `string` | | `null` | KMS key ARN for `SecureString` encryption |
| `tags` | `map(string)` | | `{}` | Common tags |

---

## Outputs

| Name | Description |
|------|-------------|
| `parameter_arns` | Map of parameter key → SSM parameter ARN |
| `parameter_names` | Map of parameter key → SSM parameter full path name |
| `parameter_types` | Map of parameter key → parameter type (`String` \| `StringList` \| `SecureString`) |
| `all_parameter_arns` | List of all created SSM parameter ARNs |

---

## Notes

- **Naming Hierarchy**: Parameter keys without a leading `/` are automatically prefixed with `/${var.project}/${var.environment}/`. Keys starting with `/` are treated as absolute paths.
- **SecureString**: Setting `sensitive = true` or `type = "SecureString"` automatically encrypts the parameter using `kms_key_arn` (or AWS default SSM key if `kms_key_arn` is null).
