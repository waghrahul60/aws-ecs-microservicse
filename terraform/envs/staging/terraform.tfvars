###############################################################################
# STAGING ENVIRONMENT - terraform.tfvars
###############################################################################

project     = "myapp"
environment = "staging"
aws_region  = "us-east-1"
cost_center = "engineering"

# Network
vpc_cidr                  = "10.20.0.0/16"
availability_zones        = ["us-east-1a", "us-east-1b"]
public_subnet_cidrs       = ["10.20.1.0/24", "10.20.2.0/24"]
private_app_subnet_cidrs  = ["10.20.10.0/24", "10.20.11.0/24"]
private_data_subnet_cidrs = ["10.20.20.0/24", "10.20.21.0/24"]

# DNS & TLS
domain_aliases                 = ["staging.myapp.example.com"]
cloudfront_acm_certificate_arn = "arn:aws:acm:us-east-1:ACCOUNT_ID:certificate/STAGING_CERT_ID"
alb_acm_certificate_arn        = "arn:aws:acm:us-east-1:ACCOUNT_ID:certificate/STAGING_CERT_ID"

# Database
db_name           = "appdb"
db_instance_class = "db.t3.medium"

# Image tags
frontend_image_tag  = "latest"
service_a_image_tag = "latest"
service_b_image_tag = "latest"
service_c_image_tag = "latest"
