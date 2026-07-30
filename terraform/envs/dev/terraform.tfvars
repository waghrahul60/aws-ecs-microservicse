# DEV ENVIRONMENT - terraform.tfvars
# ⚠️  DO NOT commit sensitive values to version control
# Use AWS SSM or a secrets management solution for passwords

project    = "myapp"
environment = "dev"
aws_region  = "us-east-1"
cost_center = "engineering"

# Network
vpc_cidr                  = "10.10.0.0/16"
availability_zones        = ["us-east-1a", "us-east-1b"]
public_subnet_cidrs       = ["10.10.1.0/24", "10.10.2.0/24"]
private_app_subnet_cidrs  = ["10.10.10.0/24", "10.10.11.0/24"]
private_data_subnet_cidrs = ["10.10.20.0/24", "10.10.21.0/24"]

# DNS & TLS – fill in your ACM certificate ARNs
domain_aliases                 = ["dev.myapp.example.com"]
cloudfront_acm_certificate_arn = "arn:aws:acm:us-east-1:ACCOUNT_ID:certificate/CERT_ID"
alb_acm_certificate_arn        = "arn:aws:acm:us-east-1:ACCOUNT_ID:certificate/CERT_ID"

# Database
db_name           = "appdb"
db_instance_class = "db.t3.small"

# Image tags (updated per deployment)
frontend_image_tag  = "latest"
service_a_image_tag = "latest"
service_b_image_tag = "latest"
service_c_image_tag = "latest"
