
module "s3_backend" {
  source      = "./modules/s3-backend"                # Path to module
  bucket_name = "terraform-state-bucket-127214174194" # S3 bucket name
  table_name  = "terraform-locks"                     # DynamoDB table name
}

module "vpc" {
  source             = "./modules/vpc"                                     # Path to VPC module
  vpc_cidr_block     = "10.0.0.0/16"                                       # CIDR block for VPC
  public_subnets     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]       # Public subnets
  private_subnets    = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]       # Private subnets
  availability_zones = ["eu-central-1a", "eu-central-1b", "eu-central-1c"] # Availability zones
  vpc_name           = "vpc"                                               # VPC name
}

module "ecr" {
  source           = "./modules/ecr"
  ecr_name         = "lesson-5-ecr"
  scan_on_push     = true
  image_mutability = "MUTABLE"

  encryption_configuration = {
    encryption_type = "AES256"
    kms_key         = null
  }

  tags = {
    Project     = "GoIT Microservice"
    ManagedBy   = "Terraform"
    Application = "lesson-5"
  }
}
