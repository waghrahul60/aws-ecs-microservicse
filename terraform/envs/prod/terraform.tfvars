###############################################################################
# PROD ENVIRONMENT - terraform.tfvars
# Production uses: Multi-AZ NAT, Multi-AZ RDS, larger task sizes,
#                  deletion protection ON, longer backup retention
###############################################################################

project     = "myapp"
environment = "prod"
aws_region  = "us-east-1"
cost_center = "engineering"

# Network
vpc_cidr                  = "10.30.0.0/16"
availability_zones        = ["us-east-1a", "us-east-1b"]
public_subnet_cidrs       = ["10.30.1.0/24", "10.30.2.0/24"]
private_app_subnet_cidrs  = ["10.30.10.0/24", "10.30.11.0/24"]
private_data_subnet_cidrs = ["10.30.20.0/24", "10.30.21.0/24"]

# DNS & TLS
domain_aliases                 = ["myapp.example.com", "www.myapp.example.com"]
cloudfront_acm_certificate_arn = "arn:aws:acm:us-east-1:ACCOUNT_ID:certificate/PROD_CERT_ID"
alb_acm_certificate_arn        = "arn:aws:acm:us-east-1:ACCOUNT_ID:certificate/PROD_CERT_ID"

# Database – Production grade
db_name           = "appdb"
db_instance_class = "db.r6g.large"

# Image tags – pinned versions in production
frontend_image_tag  = "v1.0.0"
service_a_image_tag = "v1.0.0"
service_b_image_tag = "v1.0.0"
service_c_image_tag = "v1.0.0"
