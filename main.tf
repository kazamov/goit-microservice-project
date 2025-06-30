
module "s3_backend" {
  source      = "./modules/s3-backend"                # Шлях до модуля
  bucket_name = "terraform-state-bucket-127214174194" # Ім'я S3-бакета
  table_name  = "terraform-locks"                     # Ім'я DynamoDB
}

module "vpc" {
  source             = "./modules/vpc"                                     # Шлях до модуля VPC
  vpc_cidr_block     = "10.0.0.0/16"                                       # CIDR блок для VPC
  public_subnets     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]       # Публічні підмережі
  private_subnets    = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]       # Приватні підмережі
  availability_zones = ["eu-central-1a", "eu-central-1b", "eu-central-1c"] # Зони доступності
  vpc_name           = "vpc"                                               # Ім'я VPC
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
