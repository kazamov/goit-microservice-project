# Main Infrastructure

This directory contains the main application infrastructure that uses the remote S3 backend.

## Purpose

This project creates the actual application infrastructure:
- **VPC**: Virtual Private Cloud with public/private subnets
- **ECR**: Elastic Container Registry for Docker images

## Prerequisites

Before using this project, you must first deploy the backend infrastructure:

```bash
cd ../infra-backend
terraform init
terraform apply
```

## Architecture

```
infra-backend/     ← Backend project (uses local state)
└── Creates S3 + DynamoDB for remote state

main-infra/        ← This project (uses remote state)
└── Uses the S3 backend created above
```

## Files

- `main.tf` - Main Terraform configuration with S3 backend
- `variables.tf` - Input variables with sensible defaults
- `outputs.tf` - Output values for created resources

## Usage

### 1. Initialize (first time only)

```bash
cd main-infra
terraform init
```

### 2. Plan and Apply

```bash
terraform plan
terraform apply
```

### 3. Destroy (when needed)

```bash
terraform destroy
```

The backend (S3 bucket and DynamoDB table) will remain intact, allowing you to recreate the infrastructure later.

## Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `aws_region` | AWS region | `eu-central-1` |
| `vpc_cidr_block` | VPC CIDR block | `10.0.0.0/16` |
| `public_subnets` | Public subnet CIDR blocks | `["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]` |
| `private_subnets` | Private subnet CIDR blocks | `["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]` |
| `availability_zones` | Availability zones | `["eu-central-1a", "eu-central-1b", "eu-central-1c"]` |
| `vpc_name` | VPC name | `main-vpc` |
| `ecr_name` | ECR repository name | `lesson-5-ecr` |
| `scan_on_push` | Enable ECR image scanning | `true` |
| `image_mutability` | ECR image mutability | `MUTABLE` |

## Benefits of This Architecture

✅ **Clean Separation**: Backend and application infrastructure are separate  
✅ **Safe Destroy**: Can destroy main infrastructure without affecting state storage  
✅ **No State Migration**: No complex scripts needed for destroy/recreate  
✅ **Persistent Backend**: S3 bucket and DynamoDB table persist across deployments  
✅ **Simple Recovery**: Easy to recreate infrastructure from stored state
