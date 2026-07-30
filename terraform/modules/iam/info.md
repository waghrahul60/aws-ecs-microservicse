# Module: `iam`

> Creates ECS Task Execution Role and ECS Task Role. Provisions least-privilege IAM policies for Secrets Manager, SSM Parameter Store, CloudWatch Logs, and KMS decryption access.

---

## Usage

```hcl
module "iam" {
  source = "../../modules/iam"

  project     = var.project
  environment = var.environment

  secrets_manager_arns = module.secrets_manager.all_secret_arns
  ssm_parameter_arns   = values(module.secrets_manager.ssm_parameter_arns)
  kms_key_arns         = [module.secrets_manager.kms_key_arn, module.rds.kms_key_arn]

  tags = local.common_tags
}
```

---

## Input Variables

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `project` | `string` | ✅ | — | Project name |
| `environment` | `string` | ✅ | — | Environment name |
| `secrets_manager_arns` | `list(string)` | | `["*"]` | Secret ARNs ECS roles can access |
| `ssm_parameter_arns` | `list(string)` | | `["*"]` | SSM Parameter ARNs ECS roles can access |
| `kms_key_arns` | `list(string)` | | `["*"]` | KMS key ARNs for decrypt permissions |
| `tags` | `map(string)` | | `{}` | Common tags |

---

## Outputs

| Name | Description |
|------|-------------|
| `ecs_execution_role_arn` | ECS Task Execution Role ARN |
| `ecs_execution_role_name` | ECS Task Execution Role name |
| `ecs_task_role_arn` | ECS Task Role ARN |
| `ecs_task_role_name` | ECS Task Role name |

---

## Notes

- **Execution Role**: Used by the ECS agent to pull images from ECR, fetch secrets from Secrets Manager/SSM, and stream logs to CloudWatch.
- **Task Role**: Assumed by running container tasks for application-level AWS API calls.
- **ECR Repositories**: Managed separately by the standalone `ecr` module.
