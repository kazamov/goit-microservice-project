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

# Get EKS cluster data
data "aws_eks_cluster" "eks" {
  name = module.eks.cluster_name
}

data "aws_eks_cluster_auth" "eks" {
  name = module.eks.cluster_name
}

# Configure Kubernetes provider
provider "kubernetes" {
  host                   = data.aws_eks_cluster.eks.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.eks.token
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.eks.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.eks.token
  }
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
  source        = "../modules/eks"
  cluster_name  = "eks-cluster-demo"
  subnet_ids    = module.vpc.public_subnets
  instance_type = "t2.micro"
  desired_size  = 1
  max_size      = 2
  min_size      = 1
}

module "jenkins" {
  source            = "../modules/jenkins"
  cluster_name      = module.eks.cluster_name
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.cluster_oidc_issuer_url
  kubeconfig        = ""

  providers = {
    helm = helm
  }

  depends_on = [module.eks]
}

module "argo_cd" {
  source        = "../modules/argo-cd"
  namespace     = "argocd"
  chart_version = "5.46.4"
}
