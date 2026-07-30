# Module: `rds`

> Creates a multi-AZ PostgreSQL RDS instance in private data subnets with storage auto-scaling, dedicated KMS key encryption, automated backups, DB parameter group, subnet group, and CloudWatch alarms.

---

## Usage

```hcl
module "rds" {
  source = "../../modules/rds"

  project     = var.project
  environment = var.environment

  private_data_subnet_ids = module.vpc.private_data_subnet_ids
  rds_sg_id               = module.security_groups.rds_sg_id

  postgres_major_version  = "16"
  postgres_engine_version = "16.2"
  db_instance_class       = var.db_instance_class

  allocated_storage     = 100
  max_allocated_storage = 500

  db_name     = var.db_name
  db_username = var.db_username # sensitive
  db_password = var.db_password # sensitive

  multi_az                = true
  backup_retention_period = 7

  tags = local.common_tags
}
```

---

## Input Variables

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `project` | `string` | ✅ | — | Project name |
| `environment` | `string` | ✅ | — | Environment name |
| `private_data_subnet_ids` | `list(string)` | ✅ | — | Private data-tier subnet IDs |
| `rds_sg_id` | `string` | ✅ | — | Security group ID for RDS |
| `postgres_major_version` | `string` | | `"16"` | PostgreSQL major version |
| `postgres_engine_version` | `string` | | `"16.2"` | Full PostgreSQL engine version string |
| `db_instance_class` | `string` | | `"db.t3.medium"` | RDS instance class |
| `allocated_storage` | `number` | | `100` | Initial allocated storage in GiB |
| `max_allocated_storage` | `number` | | `500` | Maximum storage limit for autoscaling in GiB |
| `db_name` | `string` | ✅ | — | Master database name |
| `db_username` | `string` | ✅ | — | Master DB username (`sensitive`) |
| `db_password` | `string` | ✅ | — | Master DB password (`sensitive`) |
| `multi_az` | `bool` | | `true` | Enable Multi-AZ deployment |
| `backup_retention_period` | `number` | | `7` | Days to retain automated backups |
| `alarm_sns_topic_arn` | `string` | | `""` | SNS topic ARN for CloudWatch alarms |
| `tags` | `map(string)` | | `{}` | Common tags |

---

## Outputs

| Name | Description |
|------|-------------|
| `db_instance_id` | RDS instance ID |
| `db_instance_arn` | RDS instance ARN |
| `db_endpoint` | RDS connection endpoint (`host:port`) |
| `db_host` | RDS hostname |
| `db_port` | RDS port |
| `db_name` | Master database name |
| `kms_key_arn` | KMS key ARN used for RDS storage encryption |
| `kms_key_id` | KMS key ID |

---

## Notes

- **KMS Encryption**: Dedicated customer-managed KMS key is created for storage and automated snapshot encryption.
- **Network Security**: Deployed into private data subnets; access is restricted via Security Group to ECS tasks only.
- **Storage Autoscaling**: Automatically scales up to `max_allocated_storage` as storage usage grows.
- Pass `kms_key_arn` to the `iam` module if task permissions require decrypt access to RDS keys.
