# Main Infrastructure

This directory contains the main application infrastructure that uses the remote S3 backend.

## Purpose

This project creates the actual application infrastructure:
- **VPC**: Virtual Private Cloud with public/private subnets and optional NAT Gateway
- **ECR**: Elastic Container Registry for Docker images

## Prerequisites

Before using this project, you must first deploy the backend infrastructure using the automated script:

```bash
./deploy-backend.sh
```

Or manually:
```bash
cd infra-backend
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

### 3. Enable NAT Gateway (Optional)

To enable private subnet internet access, set NAT Gateway variables:

```bash
# For cost-effective setup (single NAT Gateway)
terraform apply -var="enable_nat_gateway=true" -var="single_nat_gateway=true"

# For high availability setup (NAT Gateway per AZ)
terraform apply -var="enable_nat_gateway=true" -var="single_nat_gateway=false"
```

### 4. Destroy (when needed)

```bash
terraform destroy
```

The backend (S3 bucket and DynamoDB table) will remain intact, allowing you to recreate the infrastructure later.

## Variables

### Core Infrastructure

| Variable | Description | Default |
|----------|-------------|---------|
| `aws_region` | AWS region | `eu-central-1` |
| `vpc_cidr_block` | VPC CIDR block | `10.0.0.0/16` |
| `public_subnets` | Public subnet CIDR blocks | `["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]` |
| `private_subnets` | Private subnet CIDR blocks | `["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]` |
| `availability_zones` | Availability zones | `["eu-central-1a", "eu-central-1b", "eu-central-1c"]` |
| `vpc_name` | VPC name | `main-vpc` |

### NAT Gateway Configuration

| Variable | Description | Default | 
|----------|-------------|---------|
| `enable_nat_gateway` | Enable NAT Gateways for private subnets | `false` |
| `single_nat_gateway` | Use single NAT Gateway for all private subnets | `false` |

### ECR Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| `ecr_name` | ECR repository name | `lesson-7-ecr` |
| `scan_on_push` | Enable ECR image scanning | `true` |
| `image_mutability` | ECR image mutability | `MUTABLE` |

## NAT Gateway Options

### Development/Testing
```hcl
enable_nat_gateway = false  # No additional costs
```

### Cost-Effective Production
```hcl
enable_nat_gateway = true
single_nat_gateway = true   # ~$45/month + data processing
```

### High Availability Production
```hcl
enable_nat_gateway = true
single_nat_gateway = false  # ~$45/month per AZ + data processing
```

## Benefits of This Architecture

✅ **Clean Separation**: Backend and application infrastructure are separate  
✅ **Safe Destroy**: Can destroy main infrastructure without affecting state storage  
✅ **No State Migration**: No complex scripts needed for destroy/recreate  
✅ **Persistent Backend**: S3 bucket and DynamoDB table persist across deployments  
✅ **Simple Recovery**: Easy to recreate infrastructure from stored state  
✅ **Flexible Networking**: Optional NAT Gateway for private subnet internet access  
✅ **Cost Control**: Choose between no NAT, single NAT, or multi-AZ NAT based on needs

## Outputs

After deployment, the following outputs are available:

### VPC Outputs
- `vpc_id` - ID of the created VPC
- `public_subnets` - List of public subnet IDs
- `private_subnets` - List of private subnet IDs
- `internet_gateway_id` - Internet Gateway ID
- `nat_gateway_ids` - NAT Gateway IDs (if enabled)
- `nat_gateway_ips` - NAT Gateway public IPs (if enabled)
- `private_route_table_ids` - Private route table IDs
- `public_route_table_id` - Public route table ID

### ECR Outputs
- `ecr_repository_url` - ECR repository URL for Docker push/pull
- `ecr_repository_arn` - ECR repository ARN
- `ecr_repository_name` - ECR repository name
- `ecr_registry_id` - Registry ID where repository was created
