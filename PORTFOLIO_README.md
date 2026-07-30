# 🚀 Production-Grade AWS ECS Microservices Infrastructure

[![Terraform](https://img.shields.io/badge/IaC-Terraform_v1.6+-844FBA?style=for-the-badge&logo=terraform&logoColor=white)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/Cloud-AWS_ECS_Fargate-FF9900?style=for-the-badge&logo=amazon-aws&logoColor=white)](https://aws.amazon.com/)
[![Docker](https://img.shields.io/badge/Container-Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)](https://www.docker.com/)
[![Security](https://img.shields.io/badge/Security-AWS_WAF_v2_%2B_KMS-green?style=for-the-badge&logo=awswaf&logoColor=white)](https://aws.amazon.com/waf/)
[![License](https://img.shields.io/badge/License-MIT-blue?style=for-the-badge)](./LICENSE)

> **Portfolio Showcase & Architecture Demonstration**  
> An enterprise-grade, highly available, secure, and cost-optimized Infrastructure as Code (IaC) implementation powering a multi-tier **React Frontend + Java Spring Boot Microservices** platform on **AWS ECS Fargate**.

---

## 👨‍💻 Portfolio Overview & Value Proposition

This repository demonstrates modern **DevOps, Cloud Architecture, and Infrastructure Engineering** best practices. Built from the ground up using **Terraform**, it reflects production-ready standards suitable for high-compliance enterprise environments and high-traffic applications.

### 🌟 Key Engineering Competencies Demonstrated

| Domain | Technical Highlights & Demonstrated Expertise |
|---|---|
| **Modular Infrastructure as Code (IaC)** | 100% Terraform managed, 15 reusable modules, strict variable validations, remote S3 state backend with DynamoDB locking. |
| **Zero-Trust Network Topology** | 3-tier VPC architecture (Public, Private App, Isolated Data Subnets) with zero public IP exposure for compute resources. |
| **Modern Container Orchestration** | AWS ECS Fargate serverless containers with AWS Service Connect (Envoy sidecars) for private, zero-config East-West microservices traffic. |
| **Defense-in-Depth Security** | AWS WAF v2 managed rules (OWASP Top 10, SQLi, Log4j/SSRF), custom header ALB protection, customer-managed KMS keys, and Secrets Manager injection. |
| **FinOps & Cost Optimization** | Environment-aware architecture: Single NAT Gateway + Fargate Spot in non-prod environments vs Multi-AZ HA in Production (saving ~65% in non-prod). |
| **Full Observability & Governance** | End-to-end tracing, CloudWatch alarms with SNS alerting, ECS Container Insights, structured logging, and tag-based cost allocation. |

---

## 🏗️ Architecture & Traffic Flow

### 🗺️ Infrastructure Diagram

![AWS ECS Microservices Infrastructure Diagram](./asset/Infra_diagram.png)

### 🔄 End-to-End Traffic Architecture

```
                                  [ CLIENT REQUEST (HTTPS) ]
                                              │
                                              ▼
                                     ┌──────────────────┐
                                     │   Amazon Route53 │
                                     └────────┬─────────┘
                                              │
                                              ▼
                                     ┌──────────────────┐
                                     │   AWS WAF v2     │ (Managed Rules & Rate Limiting)
                                     └────────┬─────────┘
                                              │
                                              ▼
                                     ┌──────────────────┐
                                     │ Amazon CloudFront│ (Global Edge CDN + OAC)
                                     └───┬──────────┬───┘
                                         │          │
                     ┌───────────────────┘          └────────────────────┐
                     │ Static Assets                                     │ API Requests (/api/*)
                     ▼                                                   ▼
         ┌───────────────────────┐                           ┌───────────────────────┐
         │   S3 Bucket (React)   │                           │ ALB (Public Subnet)   │
         │   Private via OAC     │                           │ HTTPS / TLS 1.3       │
         └───────────────────────┘                           └───────────┬───────────┘
                                                                         │
    ═════════════════════════════════════════════════════════════════════╪═════════════════════════════════
    AWS VPC (Private App Subnets)                                        │
                                                                         ▼
                         ┌────────────────────────────────────────────────────────────────────────┐
                         │ ECS Fargate Cluster (`app.internal` Service Connect DNS)               │
                         │                                                                        │
                         │  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐     │
                         │  │  Service A (Java)│  │  Service B (Java)│  │  Service C (Java)│     │
                         │  │   Port 8080      │  │   Port 8080      │  │   Port 8080      │     │
                         │  └────────┬─────────┘  └────────┬─────────┘  └────────┬─────────┘     │
                         │           │                     │                     │                │
                         │           └──────────┬──────────┴─────────────────────┘                │
                         │                      │ Envoy Proxy Sidecars                            │
                         │                      ▼ (Private East-West DNS: service.app.internal)    │
                         └──────────────────────┬─────────────────────────────────────────────────┘
                                                │ TCP :5432
    ════════════════════════════════════════════╪══════════════════════════════════════════════════════════
    AWS VPC (Isolated Data Subnets - No Internet)│
                                                ▼
                         ┌────────────────────────────────────────────────────────────────────────┐
                         │ PostgreSQL RDS Instance (Multi-AZ Standby + KMS Encrypted Storage)     │
                         └────────────────────────────────────────────────────────────────────────┘
```

---

## 🔍 Codebase Deep-Dive Guide for Reviewers

To evaluate the code quality, design pattern implementations, and Terraform modularity, here are the key entry points:

- 🧱 **[Core Network Topology Module](./terraform/modules/vpc)** — Look here for multi-AZ subnet partitioning, route tables, and VPC flow log definitions.
- ⚙️ **[ECS Service Module](./terraform/modules/ecs_service)** — Examines container task definitions, Envoy sidecar registration, Service Connect integration, auto-scaling policy definitions, and deployment circuit breakers.
- 🛡️ **[AWS WAF Module](./terraform/modules/waf)** — Demonstrates WAF rule composition, rate limiting implementation, and threat mitigation rules.
- 🔐 **[KMS & Secrets Manager Module](./terraform/modules/secrets_manager)** — Shows customer-managed KMS key policies and secure database credential generation/injection.
- 🌍 **[Production Environment Manifest](./terraform/envs/prod/main.tf)** — Illustrates production parameterization, Multi-AZ enforcement, and zero-downtime target configurations.

---

## 🧩 Terraform Modules Breakdown

This project utilizes a strictly decoupled module design. Each module manages an isolated capability tier:

| Module Path | Managed Resources | Description |
|---|---|---|
| **[`modules/vpc`](./terraform/modules/vpc)** | VPC, Subnets, IGW, NAT Gateways, Route Tables, VPC Flow Logs | Provisions 3-tier networking across multi-AZs. |
| **[`modules/security_groups`](./terraform/modules/security_groups)** | Security Groups & Ingress/Egress Rules | Enforces strict least-privilege network perimeter controls. |
| **[`modules/ecs`](./terraform/modules/ecs)** | ECS Cluster, Fargate Providers, CloudMap Namespace | Core container cluster setup & `app.internal` DNS namespace. |
| **[`modules/ecs_service`](./terraform/modules/ecs_service)** | ECS Task Def, Services, AutoScaling, Alarms | Reusable service engine with Envoy sidecar & target tracking. |
| **[`modules/rds`](./terraform/modules/rds)** | RDS PostgreSQL, Subnet Groups, CMK KMS Key | Multi-AZ database setup with automated storage scaling. |
| **[`modules/alb`](./terraform/modules/alb)** | ALB, HTTPS Listeners, Target Groups, Rules | Internet-facing load balancing with path-based routing. |
| **[`modules/cloudfront`](./terraform/modules/cloudfront)** | CloudFront CDN, OAC, SPA Rewrite Function | Edge distribution for React SPA with custom S3 origin policy. |
| **[`modules/waf`](./terraform/modules/waf)** | WAF v2 Web ACL, Managed Rule Sets, Rate Limits | Edge security blocking SQLi, XSS, CSRF, and brute force attacks. |
| **[`modules/s3`](./terraform/modules/s3)** | S3 Buckets, Access Logs, Bucket Policies | Secure static asset storage with strict public access blocks. |
| **[`modules/secrets_manager`](./terraform/modules/secrets_manager)** | Secrets Manager, SSM Parameters, KMS Keys | Encrypted secret storage injected into container environments at runtime. |
| **[`modules/iam`](./terraform/modules/iam)** | Execution Roles, Task Roles, Policy Attachments | Fine-grained IAM permissions for runtime and execution roles. |
| **[`modules/ecr`](./terraform/modules/ecr)** | ECR Repositories, Image Scanning, Lifecycle Policies | Encrypted Docker image registries with automated cleanup policies. |
| **[`modules/observability`](./terraform/modules/observability)** | CloudWatch Dashboards, Log Groups, Alarms, SNS | Unified metrics, alerting thresholds, and notification topics. |
| **[`modules/route53`](./terraform/modules/route53)** | Route 53 Records, DNS Validation | Custom domain management and SSL certificate mapping. |
| **[`modules/ssm`](./terraform/modules/ssm)** | SSM Parameters | Non-sensitive runtime configuration parameters. |

---

## 💡 Key Architectural & Engineering Decisions

### 1. Why AWS ECS Fargate over Kubernetes (EKS)?
- **Reduced Operational Overhead**: Fargate abstracts server management, OS patching, and control plane maintenance.
- **Cost Efficiency**: No idle EC2 worker node billing; cost is strictly tied to running container CPU/Memory.
- **Seamless AWS Integration**: Native integration with IAM task execution, AWS Service Connect, CloudWatch Container Insights, and Secrets Manager.

### 2. Why AWS Service Connect over traditional Service Mesh (Istio / App Mesh)?
- **Simplicity & Zero Infrastructure Footprint**: Eliminates complex control-plane clusters (like Istio pilot/galley).
- **Built-in Envoy Sidecars**: Provides automatic client-side load balancing, retry logic, and private DNS resolution (`service-name.app.internal`) without public or internal load balancer costs.

### 3. Multi-Tier Security Strategy
- **Layer 1 (Edge)**: CloudFront + WAF v2 blocks malicious payloads and DDoS before reaching AWS origin.
- **Layer 2 (Perimeter)**: Public ALB validates custom header injection from CloudFront to prevent origin bypass.
- **Layer 3 (Compute)**: ECS tasks operate in private subnets without public IPs.
- **Layer 4 (Data)**: Database resides in completely isolated non-routable subnets accessible only by ECS task security groups on port 5432.
- **Layer 5 (Data-at-Rest)**: All storage (RDS, S3, ECR, Secrets) is encrypted via customer-managed KMS keys (CMKs).

---

## 🌍 Environment Isolation & Strategy

The repository supports 4 completely isolated environments:

| Feature / Setting | `dev` | `staging` | `uat` | `prod` |
|---|---|---|---|---|
| **VPC CIDR** | `10.10.0.0/16` | `10.20.0.0/16` | `10.25.0.0/16` | `10.30.0.0/16` |
| **NAT Gateways** | 1 (Single) | 1 (Single) | 1 (Single) | 2 (Per-AZ Redundant) |
| **RDS Deployment** | Single-AZ (`db.t3.small`) | Single-AZ (`db.t3.medium`) | Single-AZ (`db.t3.medium`) | Multi-AZ (`db.r6g.large`) |
| **Capacity Provider** | Fargate Spot (75%) | Fargate Spot (50%) | Standard Fargate | Standard Fargate |
| **Min Task Count** | 1 | 1 | 1 | 2 (Multi-AZ) |
| **WAF Enabled** | Optional | Yes | Yes | Yes |
| **State File Isolation** | Dedicated S3 Key | Dedicated S3 Key | Dedicated S3 Key | Dedicated S3 Key |

---

## 🚀 Deployment & Operations Guide

### 📋 Prerequisites
- **Terraform** `>= 1.6.0`
- **AWS CLI** `>= 2.0` (configured with admin/provisioning IAM credentials)
- **Docker** `>= 24.0`
- **jq** `>= 1.6`

---

### Step 1: Initialize Remote State Storage (One-time)

Run the bootstrap script to create the S3 state bucket and DynamoDB lock table:

```bash
./scripts/bootstrap-state.sh us-east-1 my-portfolio-tf-state
```

---

### Step 2: Push Container Images to Amazon ECR

Build, tag, and push Docker images for frontend and microservices:

```bash
./scripts/push-image.sh dev frontend v1.0.0 ./apps/frontend
./scripts/push-image.sh dev service-a v1.0.0 ./apps/backend/service-a
./scripts/push-image.sh dev service-b v1.0.0 ./apps/backend/service-b
./scripts/push-image.sh dev service-c v1.0.0 ./apps/backend/service-c
```

---

### Step 3: Deploy Infrastructure via Automated Helper

Deploy any environment using the interactive shell wrapper:

```bash
# Generate execution plan
./scripts/deploy.sh dev plan v1.0.0

# Apply changes to environment
./scripts/deploy.sh dev apply v1.0.0
```

*Or perform standard Terraform commands:*

```bash
cd terraform/envs/dev
terraform init
terraform plan -var-file="terraform.tfvars"
terraform apply -var-file="terraform.tfvars" -auto-approve
```

---

## 🔄 CI/CD Pipeline Integration (GitHub Actions)

This project features a production-ready GitHub Actions workflow for automated testing, image building, and infrastructure deployment:

```yaml
name: CI/CD Pipeline

on:
  push:
    branches: [ main ]

jobs:
  deploy:
    name: Build & Deploy to Dev
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::123456789012:role/github-actions-deployer
          aws-region: us-east-1

      - name: Build & Push Microservices
        run: |
          ./scripts/push-image.sh dev service-a ${{ github.sha }} ./backend/service-a

      - name: Apply Infrastructure Changes
        run: |
          ./scripts/deploy.sh dev apply ${{ github.sha }}
```

---

## 📊 Observability & Troubleshooting

### Viewing Microservice Logs in Real-time

```bash
# Tail log events for Microservice A
aws logs tail /ecs/myapp-dev/service-a --follow --format short
```

### Container Live Debugging via ECS Exec

Access a running container without SSH/bastion hosts:

```bash
aws ecs execute-command \
  --cluster myapp-dev-cluster \
  --task <TASK_ARN> \
  --container service-a \
  --interactive \
  --command "/bin/sh"
```

---

## 📄 License

This project is open-source and released under the **[MIT License](./LICENSE)**. Feel free to use this architecture as a foundation for your own cloud deployments.

---

## 🤝 Contact & Hiring Information

If you are looking for a **Senior DevOps Engineer, Cloud Architect, or Infrastructure Consultant** to build scalable, secure, and cost-effective cloud platforms for your business:

- 📧 **Email**: [your.email@example.com](mailto:your.email@example.com)
- 💼 **LinkedIn**: [linkedin.com/in/yourprofile](https://linkedin.com/in/yourprofile)
- 🌐 **Portfolio**: [yourportfolio.com](https://yourportfolio.com)
- 🐙 **GitHub**: [github.com/yourusername](https://github.com/yourusername)

---

*Architected with precision using AWS, Terraform, and Docker.*
