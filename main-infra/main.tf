# Main Infrastructure
# This project contains the actual application infrastructure (ECR, VPC, etc.)
# Uses remote S3 backend created by infra-backend project

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  backend "s3" {
    bucket         = "terraform-state-bucket-127214174194"
    key            = "main-infra/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source             = "../modules/vpc"
  vpc_cidr_block     = var.vpc_cidr_block
  public_subnets     = var.public_subnets
  private_subnets    = var.private_subnets
  availability_zones = var.availability_zones
  vpc_name           = var.vpc_name
  enable_nat_gateway = true
  single_nat_gateway = false
}

module "ecr" {
  source                   = "../modules/ecr"
  ecr_name                 = var.ecr_name
  scan_on_push             = var.scan_on_push
  image_mutability         = var.image_mutability
  encryption_configuration = var.encryption_configuration
  tags                     = var.tags
}
