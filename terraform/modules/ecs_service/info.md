# Module: `ecs_service`

> Reusable module for a single ECS Fargate service. Creates: Task Definition, ECS Service with Service Connect, optional ALB Target Group, Application Auto Scaling (CPU + Memory), CloudWatch Log Group, and High CPU alarm. Call once per microservice.

---

## Usage

### Frontend Service (ALB-exposed)

```hcl
module "ecs_frontend" {
  source = "../../modules/ecs_service"

  project     = var.project
  environment = var.environment
  aws_region  = var.aws_region

  service_name       = "frontend"
  vpc_id             = module.vpc.vpc_id
  ecs_cluster_arn    = module.ecs.cluster_arn
  ecs_cluster_name   = module.ecs.cluster_name
  private_subnet_ids = module.vpc.private_app_subnet_ids
  ecs_tasks_sg_id    = module.security_groups.ecs_tasks_sg_id

  ecr_repository_url = module.ecr.ecr_repository_urls["frontend"]
  image_tag          = var.frontend_image_tag
  container_port     = 3000

  execution_role_arn             = module.iam.ecs_execution_role_arn
  task_role_arn                  = module.iam.ecs_task_role_arn
  service_connect_namespace_arn  = module.ecs.service_connect_namespace_arn
  service_connect_port_name      = "frontend"

  create_target_group = true
  health_check_path   = "/"

  task_cpu    = 512
  task_memory = 1024

  desired_count = 2
  min_capacity  = 2
  max_capacity  = 10

  environment_variables = [
    { name = "NODE_ENV", value = "production" }
  ]

  tags = local.common_tags
}
```

### Internal-Only Microservice (no ALB target group)

```hcl
module "ecs_service_a" {
  source = "../../modules/ecs_service"

  # ... (same core variables as above) ...
  service_name   = "service-a"
  container_port = 8080

  create_target_group      = true   # set false if not ALB-exposed
  service_connect_port_name = "service-a"

  secrets = [
    {
      name       = "SERVICE_A_API_KEY"
      value_from = module.secrets_manager.service_secret_arns["service-a"]
    }
  ]

  tags = local.common_tags
}
```

---

## Input Variables

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `project` | `string` | ✅ | — | Project name |
| `environment` | `string` | ✅ | — | Environment name |
| `aws_region` | `string` | ✅ | — | AWS region (for CloudWatch log driver) |
| `service_name` | `string` | ✅ | — | Short service name (e.g. `frontend`, `service-a`) |
| `vpc_id` | `string` | ✅ | — | VPC ID |
| `ecs_cluster_arn` | `string` | ✅ | — | ECS Cluster ARN |
| `ecs_cluster_name` | `string` | ✅ | — | ECS Cluster name |
| `private_subnet_ids` | `list(string)` | ✅ | — | Private subnets for ECS tasks |
| `ecs_tasks_sg_id` | `string` | ✅ | — | Security group ID for ECS tasks |
| `ecr_repository_url` | `string` | ✅ | — | ECR repository URL |
| `image_tag` | `string` | | `"latest"` | Docker image tag |
| `container_port` | `number` | ✅ | — | Port the container listens on |
| `app_protocol` | `string` | | `"http"` | Service Connect protocol (`http` \| `http2` \| `grpc`) |
| `task_cpu` | `number` | | `512` | Fargate task CPU units |
| `task_memory` | `number` | | `1024` | Fargate task memory (MiB) |
| `execution_role_arn` | `string` | ✅ | — | ECS task execution IAM role ARN |
| `task_role_arn` | `string` | ✅ | — | ECS task IAM role ARN |
| `service_connect_namespace_arn` | `string` | ✅ | — | Service Connect namespace ARN |
| `service_connect_port_name` | `string` | | `null` | Port name for Service Connect (set to service name to expose) |
| `create_target_group` | `bool` | | `true` | Create an ALB target group |
| `health_check_path` | `string` | | `"/health"` | ALB health check path |
| `health_check` | `object` | | `null` | Container health check config |
| `desired_count` | `number` | | `2` | Desired task count |
| `min_capacity` | `number` | | `2` | Auto scaling minimum tasks |
| `max_capacity` | `number` | | `10` | Auto scaling maximum tasks |
| `cpu_scaling_target` | `number` | | `60` | Target CPU % for auto scaling |
| `memory_scaling_target` | `number` | | `70` | Target memory % for auto scaling |
| `environment_variables` | `list(object)` | | `[]` | Env vars (`name`/`value`) for the container |
| `secrets` | `list(object)` | | `[]` | Secrets (`name`/`value_from`) injected from Secrets Manager/SSM |
| `log_retention_days` | `number` | | `30` | CloudWatch log retention |
| `enable_execute_command` | `bool` | | `false` | Enable ECS Exec for debugging |
| `alarm_sns_topic_arn` | `string` | | `""` | SNS topic for CloudWatch alarm notifications |
| `tags` | `map(string)` | | `{}` | Common tags |

---

## Outputs

| Name | Description |
|------|-------------|
| `service_name` | ECS service name |
| `service_arn` | ECS service ARN |
| `task_definition_arn` | Task definition ARN |
| `task_definition_family` | Task definition family name |
| `target_group_arn` | ALB Target Group ARN (`null` if `create_target_group = false`) |
| `log_group_name` | CloudWatch Log Group name |
| `autoscaling_target_resource_id` | Auto Scaling resource ID |

---

## Notes

- **Service Connect**: Set `service_connect_port_name = service_name` to register the service in the `app.internal` namespace so other services can call it by DNS name.
- **ALB wiring**: Pass `target_group_arn` to the `alb` module's `*_target_group_arn` variables.
- **Deployment**: Circuit breaker with automatic rollback is enabled.
- **`desired_count` drift**: `ignore_changes = [desired_count]` is set so auto scaling can adjust counts without triggering plan diffs.
- **ECS Exec**: Set `enable_execute_command = true` for debugging. Disable in production.
