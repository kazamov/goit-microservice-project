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
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.25"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
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

# Configure Kubernetes provider conditionally - only when cluster exists
provider "kubernetes" {
  host                   = var.enable_addons ? module.eks.cluster_endpoint : null
  cluster_ca_certificate = var.enable_addons ? base64decode(module.eks.cluster_certificate_authority_data) : null
  token                  = var.enable_addons ? data.aws_eks_cluster_auth.eks[0].token : null
}

provider "helm" {
  kubernetes {
    host                   = var.enable_addons ? module.eks.cluster_endpoint : null
    cluster_ca_certificate = var.enable_addons ? base64decode(module.eks.cluster_certificate_authority_data) : null
    token                  = var.enable_addons ? data.aws_eks_cluster_auth.eks[0].token : null
  }
}

# Get EKS cluster data (only when cluster exists)
data "aws_eks_cluster" "eks" {
  count      = var.enable_addons ? 1 : 0
  name       = module.eks.cluster_name
  depends_on = [module.eks]
}

data "aws_eks_cluster_auth" "eks" {
  count      = var.enable_addons ? 1 : 0
  name       = module.eks.cluster_name
  depends_on = [module.eks]
}

module "vpc" {
  source             = "../modules/vpc"
  vpc_cidr_block     = var.vpc_cidr_block
  public_subnets     = var.public_subnets
  private_subnets    = var.private_subnets
  availability_zones = var.availability_zones
  vpc_name           = var.vpc_name
  enable_nat_gateway = false
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

module "eks" {
  source              = "../modules/eks"
  cluster_name        = "eks-cluster-demo"
  subnet_ids          = module.vpc.public_subnets
  instance_type       = "t3.medium"
  desired_size        = 2
  max_size            = 3
  min_size            = 1
  create_access_entry = false
}

module "jenkins" {
  count             = var.enable_addons ? 1 : 0
  source            = "../modules/jenkins"
  cluster_name      = module.eks.cluster_name
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.cluster_oidc_issuer_url
  kubeconfig        = ""

  providers = {
    helm       = helm
    kubernetes = kubernetes
  }

  depends_on = [module.eks]
}

module "argo_cd" {
  count         = var.enable_addons ? 1 : 0
  source        = "../modules/argo_cd"
  name          = "argocd"
  namespace     = "argocd"
  chart_version = "5.46.4"

  providers = {
    helm = helm
  }

  depends_on = [module.eks]
}

module "rds" {
  source = "../modules/rds"

  name       = "myapp-db"
  use_aurora = false

  # RDS-specific settings
  engine                     = "postgres"
  engine_version             = "17.2"
  parameter_group_family_rds = "postgres17"

  # Database configuration
  db_name  = "myapp"
  username = "postgres"
  password = "admin123AWS23"

  # Infrastructure
  vpc_id              = module.vpc.vpc_id
  subnet_private_ids  = module.vpc.private_subnets
  subnet_public_ids   = module.vpc.public_subnets
  publicly_accessible = true

  # Instance configuration
  instance_class          = "db.t3.medium"
  allocated_storage       = 20
  multi_az                = true
  backup_retention_period = 7

  # Custom parameters
  parameters = {
    max_connections            = "200"
    log_min_duration_statement = "500"
  }

  tags = {
    Environment = "dev"
    Project     = "myapp"
  }
}

module "monitoring" {
  count  = var.enable_addons ? 1 : 0
  source = "../modules/monitoring"

  namespace                = "monitoring"
  prometheus_chart_version = "51.2.0"
  prometheus_storage_size  = "10Gi"
  prometheus_retention     = "15d"
  grafana_admin_password   = "admin123AWS"
  grafana_storage_size     = "2Gi"

  depends_on_modules = [module.eks]

  providers = {
    helm       = helm
    kubernetes = kubernetes
  }

  depends_on = [module.eks]
}

