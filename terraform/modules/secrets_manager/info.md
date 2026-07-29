# Module: `secrets_manager`

> Creates AWS Secrets Manager secrets (for DB credentials and per-service secrets) and a dedicated KMS key for encryption. Optionally configures automated secret rotation via Lambda.

---

## Usage

```hcl
module "secrets_manager" {
  source = "../../modules/secrets_manager"

  project     = var.project
  environment = var.environment

  db_username = var.db_username
  db_password = var.db_password
  db_name     = var.db_name
  db_host     = module.rds.db_host

  service_secrets = {
    "service-a" = {
      API_KEY = var.service_a_api_key
    }
    "service-b" = {
      API_KEY = var.service_b_api_key
    }
    "service-c" = {
      API_KEY = var.service_c_api_key
    }
  }

  enable_secret_rotation = false

  tags = local.common_tags
}
```

---

## Input Variables

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `project` | `string` | ✅ | — | Project name |
| `environment` | `string` | ✅ | — | Environment name |
| `db_username` | `string` | ✅ | — | Database master username (`sensitive`) |
| `db_password` | `string` | ✅ | — | Database master password (`sensitive`) |
| `db_name` | `string` | ✅ | — | Database name |
| `db_host` | `string` | | `""` | Database host endpoint |
| `service_secrets` | `map(map(string))` | | `{}` | Map of service name to secret key-value pairs |
| `enable_secret_rotation` | `bool` | | `false` | Enable automatic rotation for DB credentials |
| `rotation_lambda_arn` | `string` | | `""` | Lambda function ARN for secret rotation |
| `rotation_days` | `number` | | `30` | Number of days between automatic rotations |
| `tags` | `map(string)` | | `{}` | Common tags |

---

## Outputs

| Name | Description |
|------|-------------|
| `kms_key_arn` | KMS key ARN for secrets encryption |
| `kms_key_id` | KMS key ID |
| `db_credentials_secret_arn` | ARN of the DB credentials secret |
| `db_credentials_secret_name` | Name of the DB credentials secret |
| `service_secret_arns` | Map of service name → Secrets Manager secret ARN |
| `all_secret_arns` | Flat list of all secret ARNs (useful for IAM policies) |

---

## Notes

- **KMS Encryption**: Dedicated customer-managed KMS key encrypts Secrets Manager secrets.
- **SSM Parameters**: Managed separately by the standalone `ssm` module.
- **Secret format**: DB credentials are stored as a JSON object containing `username`, `password`, `engine`, `host`, `port`, and `dbname`.
