# 🚀 AWS ECS Microservices Platform

> **Production-ready, multi-environment AWS infrastructure for a React + Java microservices platform, fully provisioned via Terraform.**

---

## 📋 Table of Contents

- [Architecture Overview](#-architecture-overview)
- [Infrastructure Diagram](#-infrastructure-diagram)
- [Features](#-features)
- [Repository Structure](#-repository-structure)
- [Modules Reference](#-modules-reference)
- [Environments](#-environments)
- [Prerequisites](#-prerequisites)
- [Getting Started](#-getting-started)
- [Deployment](#-deployment)
- [Service Communication](#-service-communication)
- [Security](#-security)
- [Observability](#-observability)
- [Secrets & Configuration Management](#-secrets--configuration-management)
- [Cost Optimization](#-cost-optimization)
- [Tagging Strategy](#-tagging-strategy)
- [CI/CD Integration](#-cicd-integration)
- [Troubleshooting](#-troubleshooting)

---

## 🏗️ Architecture Overview

This repository provisions a **highly available, secure, and scalable** microservices platform on AWS using **Amazon ECS Fargate**. The platform hosts:

| Layer | Technology | Description |
|---|---|---|
| **Frontend** | React (SPA) | Served via CloudFront CDN from S3 |
| **Backend API** | Java (Spring Boot) | 3 microservices on ECS Fargate |
| **Database** | PostgreSQL (RDS) | Multi-AZ with automated backups |
| **Service Mesh** | AWS Service Connect | Private inter-service communication |
| **CDN** | Amazon CloudFront | Global edge caching + WAF |
| **Security** | WAF, KMS, Secrets Manager | End-to-end encryption & protection |

---

## 🗺️ Infrastructure Diagram

![AWS ECS Microservices Infrastructure Diagram](./asset/Infra_diagram.png)

### Traffic Flow

```
Users (HTTPS)
    │
    ▼
Amazon Route 53  ──────────────────►  AWS WAF  ──────►  Amazon CloudFront
                                                               │
                               ┌────────────────────────────────┤
                               │                                │
                               ▼                                ▼
                        React SPA (index.html)          /api/* routes
                        from S3 Bucket                         │
                                                               ▼
                                                  Application Load Balancer (ALB)
                                                     /  /api/service-a/
                                                         /api/service-b/
                                                         /api/service-c/
                                                               │
                    ──────────────────────────────────────────────────────
                    │          AWS VPC - Private App Subnets              │
                    │  ECS Fargate Cluster (app.internal namespace)       │
                    │                                                     │
                    │  [Frontend]  [Service A]  [Service B]  [Service C] │
                    │    :3000       :8080         :8080         :8080    │
                    │   (React)     (Java)        (Java)        (Java)   │
                    │                                                     │
                    │    <--  AWS Service Connect (Envoy Proxies)  -->   │
                    │         Private DNS: service-x.app.internal         │
                    ──────────────────────────────────────────────────────
                                                               │
                                                          TCP :5432
                                                               │
                    ──────────────────────────────────────────────────────
                    │        AWS VPC - Private Data Subnets              │
                    │  PostgreSQL RDS (Primary + Standby Multi-AZ)       │
                    ──────────────────────────────────────────────────────
```

### Supporting Services

| Service | Role |
|---|---|
| **Amazon ECR** | Docker image registry for all 4 ECS services |
| **AWS Secrets Manager** | DB credentials injected into ECS tasks at runtime |
| **AWS SSM Parameter Store** | Non-sensitive configuration (region, environment, namespace) |
| **AWS KMS** | Encryption keys for RDS, Secrets Manager, and ECR |
| **Amazon CloudWatch** | Logs, metrics, and alarms for all services |
| **AWS IAM** | Fine-grained roles for ECS execution and task runtime |
| **NAT Gateway** | Allows private ECS tasks to pull images from ECR |

---

## ✨ Features

### Networking
- ✅ **Multi-AZ VPC** with public, private-app, and private-data subnet tiers
- ✅ **NAT Gateway** (single in dev/staging, per-AZ in prod) for ECR image pulls
- ✅ **Internet Gateway** for ALB public access
- ✅ **VPC Flow Logs** to CloudWatch (prod/staging)
- ✅ **Isolated data tier** subnets with no internet route for RDS

### Compute (ECS Fargate)
- ✅ **4 ECS services** on Fargate: React frontend + 3 Java microservices
- ✅ **Fargate + Fargate Spot** capacity providers for cost optimization
- ✅ **Container Insights** enabled for deep ECS metrics
- ✅ **ECS Exec** support for live container debugging
- ✅ **Deployment circuit breaker** with automatic rollback
- ✅ **CPU + Memory Auto Scaling** per service with target tracking policies

### Service Communication (AWS Service Connect)
- ✅ **AWS Service Connect** with **Envoy Proxy** sidecars on every task
- ✅ **Private DNS namespace** `app.internal` for zero-config service discovery
- ✅ **Secure internal traffic** - services talk via `http://service-name.app.internal:PORT`
- ✅ Zero-config load balancing between microservices

### Load Balancing
- ✅ **Application Load Balancer** with HTTPS (TLS 1.3) listener
- ✅ **HTTP → HTTPS redirect** (301)
- ✅ **Path-based routing**: `/api/service-a/` → Service A, `/api/service-b/` → Service B, etc.
- ✅ **ALB access logs** stored in S3

### CDN & Frontend Delivery
- ✅ **Amazon CloudFront** global edge distribution
- ✅ **Origin Access Control (OAC)** — S3 bucket accessible only via CloudFront
- ✅ **CloudFront Function** for React SPA routing (all deep links → `index.html`)
- ✅ **Long-TTL cache policy** for static assets (CSS/JS/images up to 1 year)
- ✅ **Brotli + Gzip compression** enabled
- ✅ **Custom error pages** (403/404 → `index.html`)

### Security
- ✅ **AWS WAF v2** with 4 managed rule groups:
  - AWS Managed Core Rule Set (XSS, CSRF, path traversal)
  - Known Bad Inputs (Log4j, SSRF patterns)
  - SQL Injection (SQLi) Rule Set
  - IP Rate Limiting (2000 req / 5 min per IP)
- ✅ **KMS encryption** at rest for RDS, Secrets Manager, and ECR
- ✅ **Security Groups** with least-privilege ingress/egress rules
- ✅ **No public IP** on ECS tasks (all traffic through ALB)
- ✅ **ALB custom header validation** to prevent direct ALB access bypassing WAF
- ✅ **Deletion protection** on RDS and ALB in production
- ✅ **S3 Block Public Access** on all buckets

### Database (RDS PostgreSQL)
- ✅ **PostgreSQL 16** with Multi-AZ standby (prod/staging)
- ✅ **Encrypted storage** with customer-managed KMS key
- ✅ **Enhanced monitoring** (60-second granularity)
- ✅ **Performance Insights** enabled
- ✅ **Automated backups** with 7-day retention (prod: 14 days)
- ✅ **Storage autoscaling** (100 GB → 500 GB)
- ✅ **Custom parameter group** with slow query logging

### Secrets & Configuration
- ✅ **AWS Secrets Manager** — DB credentials stored as JSON injected via ECS `secrets`
- ✅ **SSM Parameter Store** — non-sensitive config (environment, region, namespace)
- ✅ **Automatic secret rotation** support (prod)
- ✅ Secrets are **never in source code** or environment variables

### Observability
- ✅ **CloudWatch Log Groups** per service with configurable retention
- ✅ **CloudWatch Alarms** for ECS High CPU, RDS High CPU, RDS Low Free Storage
- ✅ **SNS integration** for alarm notifications
- ✅ **ECS Container Insights** for task-level metrics

### IAM & ECR
- ✅ **Least-privilege ECS Execution Role** (ECR pull + Secrets Manager get)
- ✅ **ECS Task Role** with scoped SSM + Secrets Manager + CloudWatch access
- ✅ **ECR repositories** per service with image scanning on push
- ✅ **ECR lifecycle policies** (keep last 10 tagged, expire untagged after 14 days)
- ✅ **KMS-encrypted ECR images**

### Multi-Environment Support
- ✅ **4 isolated environments**: `dev`, `staging`, `uat`, `prod`
- ✅ Each environment has its **own VPC, state file, and configuration**
- ✅ Dev/staging use **single NAT Gateway** and **single-AZ RDS** for cost savings
- ✅ Prod uses **per-AZ NAT Gateways** and **Multi-AZ RDS** for HA
- ✅ **Remote Terraform state** in S3 with DynamoDB state locking

---

## 📁 Repository Structure

```
aws-ecs-microservices/
├── asset/
│   └── Infra_diagram.png           # Architecture reference diagram
│
├── scripts/
│   ├── bootstrap-state.sh          # One-time: create S3 + DynamoDB for TF state
│   ├── deploy.sh                   # Terraform plan/apply/destroy wrapper
│   └── push-image.sh               # Build & push Docker image to ECR
│
└── terraform/
    ├── modules/                    # Reusable Terraform modules
    │   ├── vpc/                    # VPC, subnets, IGW, NAT GW, route tables
    │   ├── security_groups/        # ALB, ECS, RDS, VPC endpoint SGs
    │   ├── iam/                    # ECS roles, ECR repos, lifecycle policies
    │   ├── ecs/                    # ECS cluster, Fargate, Service Connect namespace
    │   ├── ecs_service/            # Task definition, service, auto scaling, alarms
    │   ├── rds/                    # PostgreSQL RDS, subnet group, parameter group
    │   ├── alb/                    # ALB, HTTPS listener, path-based routing rules
    │   ├── cloudfront/             # CloudFront distribution, OAC, SPA function
    │   ├── waf/                    # WAF v2 Web ACL, managed rules, rate limiting
    │   ├── s3/                     # Frontend S3 bucket, access logs bucket
    │   └── secrets_manager/        # Secrets Manager, SSM parameters, KMS keys
    │
    └── envs/                       # Environment-specific root modules
        ├── dev/
        │   ├── main.tf             # Module calls with dev settings
        │   ├── variables.tf
        │   ├── outputs.tf
        │   └── terraform.tfvars
        ├── staging/
        │   └── terraform.tfvars
        ├── uat/
        │   └── terraform.tfvars
        └── prod/
            └── terraform.tfvars
```

---

## 🧩 Modules Reference

### `modules/vpc`
| Resource | Description |
|---|---|
| `aws_vpc` | VPC with DNS hostnames/resolution |
| `aws_subnet` (public x 2) | Public subnets in AZ1 and AZ2 |
| `aws_subnet` (private_app x 2) | Private subnets for ECS tasks |
| `aws_subnet` (private_data x 2) | Isolated subnets for RDS |
| `aws_internet_gateway` | IGW for public subnet internet access |
| `aws_nat_gateway` | NAT GW(s) for private subnet outbound |
| `aws_route_table` x 3 | Public, private-app, private-data routing |
| `aws_flow_log` | VPC Flow Logs to CloudWatch |

### `modules/security_groups`
| Security Group | Inbound | Outbound |
|---|---|---|
| `alb-sg` | 443, 80 from 0.0.0.0/0 | All |
| `ecs-tasks-sg` | From ALB + self (Service Connect) | All |
| `rds-sg` | 5432 from ECS tasks only | All |
| `vpc-endpoints-sg` | 443 from private app subnets | All |

### `modules/ecs`
Creates the ECS Cluster with Fargate capacity providers and the `app.internal` Service Connect private DNS namespace.

### `modules/ecs_service`
Reusable module called once per microservice. Provisions:
- CloudWatch Log Group
- ECS Task Definition (Fargate, awsvpc mode)
- ALB Target Group (optional — for externally exposed services)
- ECS Service with Service Connect configured
- Application Auto Scaling (CPU + Memory target tracking)
- CloudWatch High CPU alarm

### `modules/rds`
| Resource | Description |
|---|---|
| `aws_db_subnet_group` | Data-tier private subnets |
| `aws_db_parameter_group` | PostgreSQL tuning (slow query logging) |
| `aws_db_instance` | PostgreSQL 16 with Multi-AZ, gp3, Performance Insights |
| `aws_kms_key` | CMK for RDS storage encryption |
| `aws_iam_role` | Enhanced monitoring IAM role |

### `modules/alb`
| Resource | Description |
|---|---|
| `aws_lb` | Internet-facing ALB in public subnets |
| `aws_lb_listener` (443) | HTTPS with TLS 1.3, routes to frontend by default |
| `aws_lb_listener` (80) | HTTP to HTTPS 301 redirect |
| `aws_lb_listener_rule` x 3 | Path-based routing for service-a/b/c |

### `modules/cloudfront`
| Resource | Description |
|---|---|
| `aws_cloudfront_origin_access_control` | Secure S3 to CloudFront access |
| `aws_cloudfront_distribution` | CDN with S3 + ALB origins |
| `aws_cloudfront_function` | SPA router (deep link → index.html) |
| `aws_cloudfront_cache_policy` | Long-TTL static asset caching |

### `modules/waf`
| Rule | Priority | Action |
|---|---|---|
| AWSManagedRulesCommonRuleSet | 10 | Block |
| AWSManagedRulesKnownBadInputsRuleSet | 20 | Block |
| AWSManagedRulesSQLiRuleSet | 30 | Block |
| IP Rate Limit (2000 req/5min) | 40 | Block |

### `modules/secrets_manager`
- DB credentials stored as JSON: `{username, password, host, port, dbname}`
- Per-service secrets for API keys
- SSM parameters for non-sensitive config
- Optional automatic rotation with Lambda

### `modules/iam`
- **Execution Role**: ECR pull, Secrets Manager `GetSecretValue`, SSM `GetParameter`, KMS `Decrypt`
- **Task Role**: CloudWatch Logs, ECS Exec (SSM Messages), Secrets Manager, SSM, KMS

### `modules/s3`
- **Frontend bucket**: Versioned, SSE-AES256, public access blocked, OAC bucket policy
- **Access logs bucket**: For CloudFront and ALB access logs, 90-day lifecycle expiry

---

## 🌍 Environments

| Environment | VPC CIDR | NAT GW | RDS | ECS Min Tasks | Purpose |
|---|---|---|---|---|---|
| `dev` | 10.10.0.0/16 | Single | Single-AZ t3.small | 1 | Development & testing |
| `staging` | 10.20.0.0/16 | Single | Single-AZ t3.medium | 1 | Integration testing |
| `uat` | 10.25.0.0/16 | Single | Single-AZ t3.medium | 1 | User acceptance testing |
| `prod` | 10.30.0.0/16 | Per-AZ | Multi-AZ r6g.large | 2 | Production traffic |

---

## 🔧 Prerequisites

| Tool | Version | Install |
|---|---|---|
| Terraform | >= 1.6.0 | https://terraform.io |
| AWS CLI | >= 2.0 | https://aws.amazon.com/cli |
| Docker | >= 24.0 | https://docker.com |
| jq | >= 1.6 | `brew install jq` |

**AWS Permissions required** — your IAM user/role needs to create: VPC, Subnets, IGW, NAT GW, ECS Cluster/Services/Task Definitions, RDS, ALB, CloudFront, WAF v2, S3, Secrets Manager, SSM, KMS, IAM Roles, ECR, CloudWatch.

---

## 🚀 Getting Started

### Step 1: Bootstrap Terraform State Backend

Run this **once** before any environment is initialized:

```bash
./scripts/bootstrap-state.sh us-east-1 myapp-terraform-state
```

Update the `backend` block in each `terraform/envs/*/main.tf` with the bucket name.

### Step 2: Configure Sensitive Variables

```bash
export TF_VAR_db_username="admin"
export TF_VAR_db_password="$(openssl rand -base64 24)"
export TF_VAR_alb_custom_header_value="$(openssl rand -hex 32)"
```

### Step 3: Update terraform.tfvars

Edit `terraform/envs/dev/terraform.tfvars`:

```hcl
cloudfront_acm_certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/xxx"
alb_acm_certificate_arn        = "arn:aws:acm:us-east-1:123456789012:certificate/yyy"
domain_aliases                 = ["dev.yourdomain.com"]
```

### Step 4: Push Docker Images

```bash
./scripts/push-image.sh dev frontend v1.0.0 ../frontend
./scripts/push-image.sh dev service-a v1.0.0 ../backend/service-a
./scripts/push-image.sh dev service-b v1.0.0 ../backend/service-b
./scripts/push-image.sh dev service-c v1.0.0 ../backend/service-c
```

### Step 5: Deploy

```bash
./scripts/deploy.sh dev plan v1.0.0
./scripts/deploy.sh dev apply v1.0.0
```

---

## 🚢 Deployment

### Manual Terraform

```bash
cd terraform/envs/dev
terraform init
terraform plan -var-file=terraform.tfvars -out=dev.tfplan
terraform apply dev.tfplan
```

### Deploy Script

```bash
./scripts/deploy.sh dev apply v1.2.3
./scripts/deploy.sh staging plan
./scripts/deploy.sh prod apply v1.2.3
```

### Targeting a Single Service

```bash
cd terraform/envs/dev
terraform apply -target=module.ecs_service_a -var="service_a_image_tag=v1.3.0"
```

---

## 🔗 Service Communication

All microservices communicate **privately** over the `app.internal` namespace via **AWS Service Connect** with Envoy Proxy sidecars.

### Internal DNS Names

| Service | Internal URL |
|---|---|
| React Frontend | http://frontend.app.internal:3000 |
| Microservice A | http://service-a.app.internal:8080 |
| Microservice B | http://service-b.app.internal:8080 |
| Microservice C | http://service-c.app.internal:8080 |

### Example - Spring Boot calling another service

```yaml
# application.yml
services:
  service-b:
    url: ${SERVICE_B_URL:http://service-b.app.internal:8080}
```

---

## 🔐 Security

### Network Isolation
- ECS tasks in **private subnets** with no public IP
- RDS in **isolated data subnets** — unreachable from the internet
- All traffic enters via ALB (HTTPS only) or CloudFront

### WAF Protection
- **Core Rule Set** blocks XSS, CSRF, path traversal
- **Known Bad Inputs** blocks Log4j, SSRF
- **SQLi Rule Set** blocks SQL injection
- **Rate Limiting** protects against DDoS and brute force

### Encryption

| Layer | Encryption |
|---|---|
| RDS at rest | KMS CMK (AES-256) |
| S3 buckets | SSE-S3 (AES-256) |
| Secrets Manager | KMS CMK |
| ECR images | KMS CMK |
| Data in transit | TLS 1.2+ everywhere |

---

## 📊 Observability

### CloudWatch Log Groups

| Log Group | Description |
|---|---|
| `/ecs/myapp-dev` | ECS Cluster-level logs |
| `/ecs/myapp-dev/frontend` | React frontend logs |
| `/ecs/myapp-dev/service-a` | Microservice A logs |
| `/ecs/myapp-dev/service-b` | Microservice B logs |
| `/ecs/myapp-dev/service-c` | Microservice C logs |

### CloudWatch Alarms

| Alarm | Threshold | Action |
|---|---|---|
| ECS service-a/b/c High CPU | > 80% for 2 min | SNS notification |
| RDS High CPU | > 80% for 10 min | SNS notification |
| RDS Low Storage | < 10 GB | SNS notification |

### Useful Commands

```bash
# View ECS service logs
aws logs filter-log-events \
  --log-group-name /ecs/myapp-dev/service-a \
  --start-time $(date -d '30 minutes ago' +%s000)

# ECS Exec into a container
aws ecs execute-command \
  --cluster myapp-dev-cluster \
  --task <TASK_ARN> \
  --container service-a \
  --interactive --command "/bin/sh"

# List running tasks
aws ecs list-tasks --cluster myapp-dev-cluster
```

---

## 🔑 Secrets & Configuration Management

### DB Credentials Secret Schema (`myapp/dev/db/credentials`)

```json
{
  "username": "admin",
  "password": "...",
  "host": "myapp-dev-postgres.xxx.us-east-1.rds.amazonaws.com",
  "port": 5432,
  "dbname": "appdb",
  "engine": "postgres"
}
```

### SSM Parameters

| Parameter | Type | Description |
|---|---|---|
| `/myapp/dev/config/aws_region` | String | AWS region |
| `/myapp/dev/config/environment` | String | Environment name |
| `/myapp/dev/config/service_connect_namespace` | String | `app.internal` |

### ECS Task Secret Injection

```hcl
secrets = [
  {
    name       = "DB_CREDENTIALS"
    value_from = "arn:aws:secretsmanager:us-east-1:123:secret:myapp/dev/db/credentials"
  }
]
```

---

## 💰 Cost Optimization

| Strategy | Environments |
|---|---|
| Single NAT Gateway | dev, staging, uat |
| Single-AZ RDS | dev, staging, uat |
| Fargate Spot capacity | dev, staging |
| Smaller task sizes (256 CPU / 512 MB) | dev |
| CloudFront price class 100 (US+Europe) | dev, staging |
| ECR lifecycle auto-cleanup | all |
| S3 object version expiry (90 days) | all |
| Log retention 14 days | dev |

---

## 🏷️ Tagging Strategy

| Tag | Example Value | Purpose |
|---|---|---|
| `Project` | `myapp` | Resource grouping |
| `Environment` | `dev` / `staging` / `uat` / `prod` | Isolation |
| `ManagedBy` | `Terraform` | Drift detection |
| `Owner` | `DevOps` | Ownership |
| `CostCenter` | `engineering` | Cost allocation |
| `Service` (ECS/ECR) | `service-a` | Per-service billing |

---

## 🔄 CI/CD Integration

### GitHub Actions Example

```yaml
name: Deploy to Dev
on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::${{ secrets.AWS_ACCOUNT_ID }}:role/github-actions-role
          aws-region: us-east-1

      - name: Build and push image
        run: |
          ./scripts/push-image.sh dev service-a ${{ github.sha }} ./backend/service-a

      - name: Terraform Apply
        run: ./scripts/deploy.sh dev apply ${{ github.sha }}
        env:
          TF_VAR_db_username: ${{ secrets.DB_USERNAME }}
          TF_VAR_db_password: ${{ secrets.DB_PASSWORD }}
          TF_VAR_alb_custom_header_value: ${{ secrets.ALB_HEADER }}
          TF_VAR_cloudfront_acm_certificate_arn: ${{ secrets.CF_ACM_ARN }}
          TF_VAR_alb_acm_certificate_arn: ${{ secrets.ALB_ACM_ARN }}
```

---

## 🛠️ Troubleshooting

### ECS Task Fails to Start

```bash
aws ecs describe-tasks \
  --cluster myapp-dev-cluster \
  --tasks <TASK_ARN> \
  --query 'tasks[0].stoppedReason'
```

### Container Cannot Pull from ECR

- Verify ECS Execution Role has `AmazonECSTaskExecutionRolePolicy`
- Check NAT Gateway is attached to the private-app route table
- Optionally add ECR VPC Interface endpoints to avoid NAT

### Service-to-Service Communication Fails

```bash
aws ecs execute-command --cluster myapp-dev-cluster \
  --task <TASK_ARN> --container service-a \
  --interactive --command "curl http://service-b.app.internal:8080/health"
```

- Verify Service Connect is enabled on both services
- Confirm both services share the same `app.internal` namespace ARN

### RDS Connection Refused

- Verify ECS task SG is referenced in the RDS inbound security group rule
- RDS must be in `private_data` subnet group (not public subnets)
- Test: `nc -zv <rds-host> 5432` from inside the container

### CloudFront Returns 403

- Ensure S3 bucket policy references the correct CloudFront Distribution ARN
- OAC ID must be attached to the S3 origin in the CloudFront distribution
- Direct S3 URL should be blocked — CloudFront URL should work

---

## 📄 License

MIT License — see [LICENSE](./LICENSE) for details.

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feat/your-feature`
3. Run `terraform fmt` and `terraform validate` before committing
4. Submit a PR with a description of changes and the environment you tested

---

*Built with love using Terraform + AWS ECS Fargate*
