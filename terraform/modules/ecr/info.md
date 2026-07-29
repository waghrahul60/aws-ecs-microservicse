# Module: `ecr`

> Creates Amazon ECR repositories per microservice with image scanning on push, optional KMS encryption, tag mutability controls, and lifecycle policies to automatically clean up old images.

---

## Usage

```hcl
module "ecr" {
  source = "../../modules/ecr"

  project     = var.project
  environment = var.environment

  service_names = ["frontend", "service-a", "service-b", "service-c"]

  image_tag_mutability          = "MUTABLE"
  scan_on_push                  = true
  max_tagged_image_count        = 10
  untagged_image_retention_days = 14

  tags = local.common_tags
}
```

---

## Input Variables

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `project` | `string` | ✅ | — | Project name |
| `environment` | `string` | ✅ | — | Environment name |
| `service_names` | `list(string)` | | `["frontend", "service-a", "service-b", "service-c"]` | Microservice names to create ECR repos for |
| `image_tag_mutability` | `string` | | `"MUTABLE"` | Tag mutability (`MUTABLE` \| `IMMUTABLE`) |
| `scan_on_push` | `bool` | | `true` | Enable vulnerability scanning on push |
| `ecr_kms_key_arn` | `string` | | `""` | KMS key ARN for encryption (leave empty for AWS managed key) |
| `max_tagged_image_count` | `number` | | `10` | Max tagged images to keep per repo |
| `untagged_image_retention_days` | `number` | | `14` | Days before untagged images expire |
| `tags` | `map(string)` | | `{}` | Common tags |

---

## Outputs

| Name | Description |
|------|-------------|
| `ecr_repository_urls` | Map of service name → ECR repository URL |
| `ecr_repository_arns` | Map of service name → ECR repository ARN |
| `ecr_repository_names` | Map of service name → ECR repository name |

---

## Notes

- **Naming Convention**: Repositories are named `{project}/{environment}/{service_name}` (e.g. `myapp/dev/frontend`).
- **Integration**: The `ecr_repository_urls` output map is passed directly to each `ecs_service` module's `ecr_repository_url` variable.
