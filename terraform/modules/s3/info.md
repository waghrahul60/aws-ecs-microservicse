# Module: `s3`

> Creates the React frontend S3 bucket (private, OAC-only access via CloudFront) and an optional access logs bucket. Bucket names are globally unique via the AWS account ID suffix.

---

## Usage

```hcl
module "s3" {
  source = "../../modules/s3"

  project     = var.project
  environment = var.environment
  account_id  = data.aws_caller_identity.current.account_id

  # The CloudFront distribution ARN is required to write the bucket policy.
  # Because of the circular dependency, create the distribution first, then pass its ARN.
  cloudfront_distribution_arn = module.cloudfront.distribution_arn

  create_access_log_bucket = true
  log_retention_days       = 90

  tags = local.common_tags
}
```

---

## Input Variables

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `project` | `string` | ✅ | — | Project name |
| `environment` | `string` | ✅ | — | Environment name |
| `account_id` | `string` | ✅ | — | AWS account ID (for globally unique bucket names) |
| `cloudfront_distribution_arn` | `string` | ✅ | — | CloudFront distribution ARN for OAC bucket policy |
| `create_access_log_bucket` | `bool` | | `true` | Whether to create the access logs bucket |
| `log_retention_days` | `number` | | `90` | Days before access log objects expire |
| `tags` | `map(string)` | | `{}` | Common tags |

---

## Outputs

| Name | Description |
|------|-------------|
| `frontend_bucket_id` | Frontend S3 bucket name |
| `frontend_bucket_arn` | Frontend S3 bucket ARN |
| `frontend_bucket_regional_domain_name` | Regional domain name for CloudFront origin |
| `access_log_bucket_id` | Access logs bucket name (`null` if not created) |
| `access_log_bucket_domain_name` | Access logs bucket domain name for CloudFront logging (`null` if not created) |

---

## Notes

- The frontend bucket has **block all public access** enabled. Objects are served exclusively via CloudFront with OAC (Origin Access Control).
- Bucket names follow the pattern: `{project}-{environment}-frontend-{account_id}` (globally unique).
- Pass `frontend_bucket_regional_domain_name` → `cloudfront` module's `s3_bucket_regional_domain_name`.
- Pass `access_log_bucket_id` → `alb` module's `access_log_bucket_id`.
- Pass `access_log_bucket_domain_name` → `cloudfront` module's `access_log_bucket_domain_name`.
