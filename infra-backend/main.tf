# Terraform Backend Infrastructure
# This project creates the S3 bucket and DynamoDB table needed for remote state storage
# Uses local state since it's the foundation for remote state

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

module "s3_backend" {
  source      = "../modules/s3-backend"
  bucket_name = var.bucket_name
  table_name  = var.table_name
}

# Optionally create an empty state file to bootstrap the backend
resource "aws_s3_object" "empty_state" {
  count  = var.create_empty_state ? 1 : 0
  bucket = module.s3_backend.s3_bucket_name
  key    = var.state_key
  content = jsonencode({
    version           = 4
    terraform_version = "1.0.0"
    serial            = 1
    lineage           = uuid()
    resources         = []
  })

  tags = {
    Name      = "Empty Terraform State"
    Purpose   = "Bootstrap remote backend"
    ManagedBy = "Terraform"
  }
}
