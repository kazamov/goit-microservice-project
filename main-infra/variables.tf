variable "aws_region" {
  description = "AWS region for the infrastructure"
  type        = string
  default     = "eu-central-1"
}

# VPC Variables
variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnets" {
  description = "List of public subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "private_subnets" {
  description = "List of private subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
}

variable "availability_zones" {
  description = "List of availability zones for subnets"
  type        = list(string)
  default     = ["eu-central-1a", "eu-central-1b", "eu-central-1c"]
}

variable "vpc_name" {
  description = "Name tag for the VPC"
  type        = string
  default     = "main-vpc"
}

variable "enable_nat_gateway" {
  description = "Should be true if you want to provision NAT Gateways for each of your private networks"
  type        = bool
  default     = false
}

variable "single_nat_gateway" {
  description = "Should be true if you want to provision a single shared NAT Gateway across all of your private networks"
  type        = bool
  default     = false
}

# ECR Variables
variable "ecr_name" {
  description = "Name of the ECR repository"
  type        = string
  default     = "django_app"
}

variable "scan_on_push" {
  description = "Enable image scanning on push"
  type        = bool
  default     = true
}

variable "image_mutability" {
  description = "Image tag mutability setting"
  type        = string
  default     = "MUTABLE"
  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE"], var.image_mutability)
    error_message = "Image mutability must be either MUTABLE or IMMUTABLE."
  }
}

variable "encryption_configuration" {
  description = "ECR encryption configuration"
  type = object({
    encryption_type = string
    kms_key         = string
  })
  default = {
    encryption_type = "AES256"
    kms_key         = null
  }
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    Project     = "GoIT Microservice"
    ManagedBy   = "Terraform"
    Application = "lesson-7"
  }
}
