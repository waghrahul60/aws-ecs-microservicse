###############################################################################
# PRODUCTION ENVIRONMENT - main.tf
# Calls all shared infrastructure modules for the Production environment.
#
# Provider config  → provider.tf
# Backend config   → backend.conf  (terraform init -backend-config=backend.conf)
###############################################################################

# ─────────────────────────────────────────────
# Module: VPC
# ─────────────────────────────────────────────
module "vpc" {
  source = "../../modules/vpc"

  project                   = local.project
  environment               = local.environment
  vpc_cidr                  = var.vpc_cidr
  availability_zones        = var.availability_zones
  public_subnet_cidrs       = var.public_subnet_cidrs
  private_app_subnet_cidrs  = var.private_app_subnet_cidrs
  private_data_subnet_cidrs = var.private_data_subnet_cidrs
  single_nat_gateway        = false # Dual NAT Gateways for High Availability
  enable_flow_logs          = true  # Enable Flow Logs in Production
  tags                      = local.common_tags
}

# ─────────────────────────────────────────────
# Module: Security Groups
# ─────────────────────────────────────────────
module "security_groups" {
  source = "../../modules/security_groups"

  project                  = local.project
  environment              = local.environment
  vpc_id                   = module.vpc.vpc_id
  private_app_subnet_cidrs = var.private_app_subnet_cidrs
  alb_ingress_cidr_blocks  = ["10.0.0.0/8", "172.16.0.0/12"]
  tags                     = local.common_tags
}

# ─────────────────────────────────────────────
# Module: WAF (us-east-1 provider required)
# ─────────────────────────────────────────────
module "waf" {
  source = "../../modules/waf"
  providers = {
    aws = aws.us_east_1
  }

  project           = local.project
  environment       = local.environment
  rate_limit_per_ip = 3000
  tags              = local.common_tags
}

# ─────────────────────────────────────────────
# Module: ECR (IMMUTABLE image tags in prod)
# ─────────────────────────────────────────────
module "ecr" {
  source = "../../modules/ecr"

  project              = local.project
  environment          = local.environment
  service_names        = ["frontend", "service-a", "service-b", "service-c"]
  image_tag_mutability = "IMMUTABLE" # Strict immutability in Prod
  scan_on_push         = true
  tags                 = local.common_tags
}

# ─────────────────────────────────────────────
# Module: IAM
# ─────────────────────────────────────────────
module "iam" {
  source = "../../modules/iam"

  project     = local.project
  environment = local.environment
  tags        = local.common_tags
}

# ─────────────────────────────────────────────
# Module: Secrets Manager
# ─────────────────────────────────────────────
module "secrets_manager" {
  source = "../../modules/secrets_manager"

  project     = local.project
  environment = local.environment

  db_username = var.db_username
  db_password = var.db_password
  db_host     = module.rds.db_host
  db_name     = var.db_name

  service_secrets = {
    "service-a" = { INTERNAL_API_KEY = var.service_a_api_key }
    "service-b" = { INTERNAL_API_KEY = var.service_b_api_key }
    "service-c" = { INTERNAL_API_KEY = var.service_c_api_key }
  }

  enable_secret_rotation = true # Automated secret rotation in Prod

  tags = local.common_tags

  depends_on = [module.rds]
}

# ─────────────────────────────────────────────
# Module: SSM Parameter Store
# ─────────────────────────────────────────────
module "ssm" {
  source = "../../modules/ssm"

  project     = local.project
  environment = local.environment

  kms_key_arn = module.secrets_manager.kms_key_arn

  parameters = {
    "config/aws_region"                = { value = var.aws_region, description = "AWS region", sensitive = false }
    "config/environment"               = { value = local.environment, description = "Environment name", sensitive = false }
    "config/service_connect_namespace" = { value = "app.internal", description = "Service Connect internal namespace", sensitive = false }
  }

  tags = local.common_tags
}

# ─────────────────────────────────────────────
# Module: S3 Buckets
# ─────────────────────────────────────────────
module "s3" {
  source = "../../modules/s3"

  project                     = local.project
  environment                 = local.environment
  account_id                  = local.account_id
  cloudfront_distribution_arn = module.cloudfront.distribution_arn
  create_access_log_bucket    = true
  log_retention_days          = 90
  tags                        = local.common_tags
}

# ─────────────────────────────────────────────
# Module: CloudFront Distribution
# ─────────────────────────────────────────────
module "cloudfront" {
  source = "../../modules/cloudfront"

  project                        = local.project
  environment                    = local.environment
  s3_bucket_regional_domain_name = module.s3.frontend_bucket_regional_domain_name
  alb_dns_name                   = module.alb.alb_dns_name
  alb_custom_header_value        = var.alb_custom_header_value
  waf_web_acl_arn                = module.waf.web_acl_arn
  acm_certificate_arn            = var.cloudfront_acm_certificate_arn
  domain_aliases                 = var.domain_aliases
  access_log_bucket_domain_name  = module.s3.access_log_bucket_domain_name
  tags                           = local.common_tags

  depends_on = [module.s3, module.waf]
}

# ─────────────────────────────────────────────
# Module: ECS Cluster
# ─────────────────────────────────────────────
module "ecs" {
  source = "../../modules/ecs"

  project                   = local.project
  environment               = local.environment
  vpc_id                    = module.vpc.vpc_id
  service_connect_namespace = "app.internal"
  log_retention_days        = 90
  tags                      = local.common_tags
}

# ─────────────────────────────────────────────
# Module: RDS PostgreSQL (Multi-AZ in Production)
# ─────────────────────────────────────────────
module "rds" {
  source = "../../modules/rds"

  project                 = local.project
  environment             = local.environment
  private_data_subnet_ids = module.vpc.private_data_subnet_ids
  rds_sg_id               = module.security_groups.rds_sg_id
  db_instance_class       = var.db_instance_class
  db_name                 = var.db_name
  db_username             = var.db_username
  db_password             = var.db_password
  multi_az                = true # High availability in Prod
  backup_retention_period = 30
  tags                    = local.common_tags
}

# ─────────────────────────────────────────────
# Module: ECS Services (Prod Sizing & Auto Scaling)
# ─────────────────────────────────────────────
module "ecs_service_frontend" {
  source = "../../modules/ecs_service"

  project                       = local.project
  environment                   = local.environment
  aws_region                    = var.aws_region
  service_name                  = "frontend"
  vpc_id                        = module.vpc.vpc_id
  ecs_cluster_arn               = module.ecs.cluster_arn
  ecs_cluster_name              = module.ecs.cluster_name
  private_subnet_ids            = module.vpc.private_app_subnet_ids
  ecs_tasks_sg_id               = module.security_groups.ecs_tasks_sg_id
  ecr_repository_url            = module.ecr.ecr_repository_urls["frontend"]
  image_tag                     = var.frontend_image_tag
  container_port                = 3000
  task_cpu                      = 512
  task_memory                   = 1024
  desired_count                 = 2
  min_capacity                  = 2
  max_capacity                  = 10
  execution_role_arn            = module.iam.ecs_execution_role_arn
  task_role_arn                 = module.iam.ecs_task_role_arn
  service_connect_namespace_arn = module.ecs.service_connect_namespace_arn
  service_connect_port_name     = "frontend"
  create_target_group           = true
  health_check_path             = "/"
  tags                          = local.common_tags
}

module "ecs_service_a" {
  source = "../../modules/ecs_service"

  project                       = local.project
  environment                   = local.environment
  aws_region                    = var.aws_region
  service_name                  = "service-a"
  vpc_id                        = module.vpc.vpc_id
  ecs_cluster_arn               = module.ecs.cluster_arn
  ecs_cluster_name              = module.ecs.cluster_name
  private_subnet_ids            = module.vpc.private_app_subnet_ids
  ecs_tasks_sg_id               = module.security_groups.ecs_tasks_sg_id
  ecr_repository_url            = module.ecr.ecr_repository_urls["service-a"]
  image_tag                     = var.service_a_image_tag
  container_port                = 8080
  task_cpu                      = 1024
  task_memory                   = 2048
  desired_count                 = 2
  min_capacity                  = 2
  max_capacity                  = 10
  execution_role_arn            = module.iam.ecs_execution_role_arn
  task_role_arn                 = module.iam.ecs_task_role_arn
  service_connect_namespace_arn = module.ecs.service_connect_namespace_arn
  service_connect_port_name     = "service-a"
  create_target_group           = true
  health_check_path             = "/actuator/health"

  secrets = [
    { name = "DB_CREDENTIALS", value_from = module.secrets_manager.db_credentials_secret_arn }
  ]

  environment_variables = [
    { name = "SPRING_PROFILES_ACTIVE", value = "prod" },
    { name = "SERVICE_B_URL", value = "http://service-b.app.internal:8080" },
    { name = "SERVICE_C_URL", value = "http://service-c.app.internal:8080" }
  ]

  tags = local.common_tags
}

module "ecs_service_b" {
  source = "../../modules/ecs_service"

  project                       = local.project
  environment                   = local.environment
  aws_region                    = var.aws_region
  service_name                  = "service-b"
  vpc_id                        = module.vpc.vpc_id
  ecs_cluster_arn               = module.ecs.cluster_arn
  ecs_cluster_name              = module.ecs.cluster_name
  private_subnet_ids            = module.vpc.private_app_subnet_ids
  ecs_tasks_sg_id               = module.security_groups.ecs_tasks_sg_id
  ecr_repository_url            = module.ecr.ecr_repository_urls["service-b"]
  image_tag                     = var.service_b_image_tag
  container_port                = 8080
  task_cpu                      = 1024
  task_memory                   = 2048
  desired_count                 = 2
  min_capacity                  = 2
  max_capacity                  = 10
  execution_role_arn            = module.iam.ecs_execution_role_arn
  task_role_arn                 = module.iam.ecs_task_role_arn
  service_connect_namespace_arn = module.ecs.service_connect_namespace_arn
  service_connect_port_name     = "service-b"
  create_target_group           = true
  health_check_path             = "/actuator/health"

  secrets = [
    { name = "DB_CREDENTIALS", value_from = module.secrets_manager.db_credentials_secret_arn }
  ]

  environment_variables = [
    { name = "SPRING_PROFILES_ACTIVE", value = "prod" },
    { name = "SERVICE_C_URL", value = "http://service-c.app.internal:8080" }
  ]

  tags = local.common_tags
}

module "ecs_service_c" {
  source = "../../modules/ecs_service"

  project                       = local.project
  environment                   = local.environment
  aws_region                    = var.aws_region
  service_name                  = "service-c"
  vpc_id                        = module.vpc.vpc_id
  ecs_cluster_arn               = module.ecs.cluster_arn
  ecs_cluster_name              = module.ecs.cluster_name
  private_subnet_ids            = module.vpc.private_app_subnet_ids
  ecs_tasks_sg_id               = module.security_groups.ecs_tasks_sg_id
  ecr_repository_url            = module.ecr.ecr_repository_urls["service-c"]
  image_tag                     = var.service_c_image_tag
  container_port                = 8080
  task_cpu                      = 1024
  task_memory                   = 2048
  desired_count                 = 2
  min_capacity                  = 2
  max_capacity                  = 10
  execution_role_arn            = module.iam.ecs_execution_role_arn
  task_role_arn                 = module.iam.ecs_task_role_arn
  service_connect_namespace_arn = module.ecs.service_connect_namespace_arn
  service_connect_port_name     = "service-c"
  create_target_group           = true
  health_check_path             = "/actuator/health"

  secrets = [
    { name = "DB_CREDENTIALS", value_from = module.secrets_manager.db_credentials_secret_arn }
  ]

  environment_variables = [
    { name = "SPRING_PROFILES_ACTIVE", value = "prod" }
  ]

  tags = local.common_tags
}

# ─────────────────────────────────────────────
# Module: ALB
# ─────────────────────────────────────────────
module "alb" {
  source = "../../modules/alb"

  project                    = local.project
  environment                = local.environment
  alb_sg_id                  = module.security_groups.alb_sg_id
  public_subnet_ids          = module.vpc.public_subnet_ids
  acm_certificate_arn        = var.alb_acm_certificate_arn
  frontend_target_group_arn  = module.ecs_service_frontend.target_group_arn
  service_a_target_group_arn = module.ecs_service_a.target_group_arn
  service_b_target_group_arn = module.ecs_service_b.target_group_arn
  service_c_target_group_arn = module.ecs_service_c.target_group_arn
  access_log_bucket_id       = module.s3.access_log_bucket_id
  tags                       = local.common_tags
}

# ─────────────────────────────────────────────
# Module: Observability (Dashboard & Alarms)
# ─────────────────────────────────────────────
module "observability" {
  source = "../../modules/observability"

  project     = local.project
  environment = local.environment
  aws_region  = var.aws_region

  ecs_cluster_name           = module.ecs.cluster_name
  db_instance_id             = module.rds.db_instance_id
  cloudfront_distribution_id = module.cloudfront.distribution_id

  tags = local.common_tags
}

# ─────────────────────────────────────────────
# Module: Route 53 & DNS
# ─────────────────────────────────────────────
module "route53" {
  source = "../../modules/route53"

  project     = local.project
  environment = local.environment

  domain_name = length(var.domain_aliases) > 0 ? var.domain_aliases[0] : ""
  create_zone = false

  domain_aliases            = var.domain_aliases
  cloudfront_domain_name    = module.cloudfront.distribution_domain_name
  cloudfront_hosted_zone_id = module.cloudfront.distribution_hosted_zone_id

  alb_dns_name       = module.alb.alb_dns_name
  alb_hosted_zone_id = module.alb.alb_zone_id

  tags = local.common_tags
}
