# GoIT Microservice Terraform Project

This project provides a complete AWS infrastructure setup for microservices using Terraform, with proper state management and modular architecture.

## Project Structure

```
├── deploy-backend.sh     # Automated backend deployment script
├── validate-backend.sh   # Configuration validation script
├── infra-backend/        # Backend infrastructure (S3 + DynamoDB)
├── main-infra/          # Main application infrastructure (VPC + ECR)
└── modules/             # Reusable Terraform modules
    ├── ecr/            # Elastic Container Registry module
    ├── s3-backend/     # S3 backend storage module
    └── vpc/            # Virtual Private Cloud module
```

## Architecture

```
┌─────────────────┐    ┌─────────────────┐
│  infra-backend  │    │   main-infra    │
│                 │    │                 │
│ • S3 Bucket     │◄───┤ • VPC           │
│ • DynamoDB      │    │ • ECR           │
│ • Local State   │    │ • Remote State  │
└─────────────────┘    └─────────────────┘
```

## Quick Start

### 1. Validate Configuration (Recommended)

```bash
./validate-backend.sh
```

### 2. Deploy Backend Infrastructure

```bash
./deploy-backend.sh
```

### 3. Deploy Main Infrastructure

```bash
./deploy-main.sh
```

### 4. Cleanup (when needed)

```bash
# Destroy main infrastructure first
cd main-infra
terraform destroy

# Then destroy backend if needed
cd ../infra-backend
terraform destroy
```

## Key Benefits

✅ **Automated Deployment**: Scripts handle validation and deployment  
✅ **Clean Architecture**: Separate backend and application concerns  
✅ **Safe Operations**: Destroy main infrastructure without affecting state  
✅ **Secure by Default**: Encrypted S3, DynamoDB locking, private subnets  
✅ **Best Practices**: Follows Terraform state management recommendations  

## Documentation

- [Backend Infrastructure](./infra-backend/README.md) - S3 + DynamoDB setup
- [Main Infrastructure](./main-infra/README.md) - VPC + ECR setup
- [ECR Module](./modules/ecr/README.md) - Container registry module
- [S3 Backend Module](./modules/s3-backend/README.md) - State storage module
- [VPC Module](./modules/vpc/README.md) - Networking module

## Module Documentation

Each module includes comprehensive documentation with usage examples and best practices:

| Module | Purpose | Documentation |
|--------|---------|---------------|
| **[S3 Backend](./modules/s3-backend/README.md)** | Remote state storage and locking | Complete setup guide, security considerations |
| **[VPC](./modules/vpc/README.md)** | Network infrastructure and subnets | Architecture diagrams, use cases, extensions |
| **[ECR](./modules/ecr/README.md)** | Container registry with security | Docker integration, lifecycle policies |

## Configuration

### Key Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `aws_region` | AWS region for resources | `eu-central-1` |
| `bucket_name` | S3 bucket for state (must be unique) | `terraform-state-bucket-127214174194` |
| `table_name` | DynamoDB table for state locking | `terraform-locks` |
| `vpc_cidr_block` | VPC CIDR block | `10.0.0.0/16` |

### Environment Variables (Optional)
```bash
export AWS_REGION=eu-central-1
export AWS_PROFILE=your-profile
```

## Common Operations

```bash
# Validate configuration
./validate-backend.sh

# Deploy backend infrastructure
./deploy-backend.sh

# View infrastructure
terraform show
terraform state list

# Use ECR repository
ECR_URL=$(terraform output -raw ecr_repository_url)
aws ecr get-login-password --region eu-central-1 | docker login --username AWS --password-stdin $ECR_URL
docker push $ECR_URL:latest
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| S3 bucket already exists | Update `bucket_name` variable with unique suffix |
| State lock issues | `terraform force-unlock LOCK_ID` |
| AWS permission errors | Check IAM permissions and AWS credentials |
| Terraform validation fails | Run `./validate-backend.sh` for detailed errors |

## Security Features

- ✅ **State Security**: Encrypted S3 storage with DynamoDB locking
- ✅ **Network Security**: Public/private subnet separation
- ✅ **Container Security**: ECR vulnerability scanning and lifecycle policies
- ✅ **Access Control**: S3 bucket public access blocked by default

## Next Steps

After deployment, consider:
- Adding monitoring with CloudWatch
- Implementing CI/CD pipelines
- Adding NAT Gateways for private subnet internet access
- Setting up VPC endpoints for AWS services

---

**For comprehensive documentation and advanced configuration, refer to the module-specific README files.**