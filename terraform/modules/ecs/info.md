# Module: `ecs`

> Creates the ECS Cluster (Fargate + Fargate Spot capacity providers with Container Insights enabled), a Service Connect private DNS namespace (`app.internal`), and a shared CloudWatch Log Group for the cluster.

---

## Usage

```hcl
module "ecs" {
  source = "../../modules/ecs"

  project     = var.project
  environment = var.environment
  vpc_id      = module.vpc.vpc_id

  service_connect_namespace = "app.internal"  # default
  log_retention_days        = 30

  tags = local.common_tags
}
```

---

## Input Variables

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `project` | `string` | ✅ | — | Project name |
| `environment` | `string` | ✅ | — | Environment name |
| `vpc_id` | `string` | ✅ | — | VPC ID for the Service Connect namespace |
| `service_connect_namespace` | `string` | | `"app.internal"` | Private DNS namespace for inter-service discovery |
| `log_retention_days` | `number` | | `30` | CloudWatch log retention in days |
| `tags` | `map(string)` | | `{}` | Common tags |

---

## Outputs

| Name | Description |
|------|-------------|
| `cluster_id` | ECS Cluster ID |
| `cluster_name` | ECS Cluster name |
| `cluster_arn` | ECS Cluster ARN |
| `service_connect_namespace_arn` | ARN of the Service Connect private DNS namespace |
| `service_connect_namespace_id` | ID of the Service Connect private DNS namespace |
| `service_connect_namespace_name` | Name of the namespace (e.g. `app.internal`) |
| `ecs_log_group_name` | CloudWatch Log Group name for the ECS cluster |

---

## Notes

- **Capacity providers**: `FARGATE` (base=1, weight=100) and `FARGATE_SPOT` are both registered. Spot usage is opt-in per service.
- **Service Connect**: The `app.internal` namespace allows microservices to discover each other by DNS name (e.g. `http://service-a:8080`). Pass `service_connect_namespace_arn` to each `ecs_service` module.
- **Container Insights**: Enabled by default for CloudWatch metrics.
- This module creates the cluster only. Individual services are created by the `ecs_service` module.
