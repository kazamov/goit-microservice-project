# GoIT Microservice Terraform Project

This project is split into two separate Terraform configurations for better state management:

## Project Structure

```
├── infra-backend/     # Backend infrastructure (S3 + DynamoDB)
├── main-infra/        # Main application infrastructure (VPC + ECR)
└── modules/           # Reusable Terraform modules
    ├── ecr/          # Elastic Container Registry module
    ├── s3-backend/   # S3 backend storage module
    └── vpc/          # Virtual Private Cloud module
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

### 1. Deploy Backend Infrastructure

```bash
cd infra-backend
terraform init
terraform apply
```

### 2. Deploy Main Infrastructure

```bash
cd ../main-infra
terraform init
terraform apply
```

### 3. Destroy (when needed)

```bash
# Destroy main infrastructure (keeps backend)
cd main-infra
terraform destroy

# Optional: Destroy backend (removes state storage)
cd ../infra-backend
terraform destroy
```

## Key Benefits

✅ **Clean Architecture**: Separate backend and application concerns  
✅ **Safe Operations**: Destroy main infrastructure without affecting state  
✅ **No Chicken-and-Egg**: Backend exists independently of application  
✅ **Simple Recovery**: Easy to recreate from stored state  
✅ **Best Practices**: Follows Terraform state management recommendations  

## Documentation

- [Backend Infrastructure](./infra-backend/README.md) - S3 + DynamoDB setup
- [Main Infrastructure](./main-infra/README.md) - VPC + ECR setup
- [ECR Module](./modules/ecr/README.md) - Container registry module
- [S3 Backend Module](./modules/s3-backend/README.md) - State storage module
- [VPC Module](./modules/vpc/README.md) - Networking module

## Previous Architecture (Deprecated)

The old single-project approach had issues with state management during destroy operations. This new split approach eliminates those problems entirely.
   git clone <repository-url>
   cd goit-microservice-project
   
   # Update bucket name in main.tf to be globally unique
   # bucket_name = "terraform-state-bucket-YOUR-UNIQUE-ID"
   ```

2. **Initial deployment (without remote state)**
   ```bash
   # Comment out backend configuration in backend.tf
   terraform init
   terraform plan
   terraform apply
   ```

3. **Migrate to remote state**
   ```bash
   # Uncomment backend configuration in backend.tf
   terraform init -migrate-state
   ```

## � Module Documentation

Each module includes comprehensive documentation with usage examples, best practices, and troubleshooting:

| Module | Purpose | Documentation |
|--------|---------|---------------|
| **[S3 Backend](./modules/s3-backend/README.md)** | Remote state storage and locking | Complete setup guide, security considerations |
| **[VPC](./modules/vpc/README.md)** | Network infrastructure and subnets | Architecture diagrams, use cases, extensions |
| **[ECR](./modules/ecr/README.md)** | Container registry with security | Docker integration, lifecycle policies |

## ⚙️ Configuration

### Key Variables

| Variable | Description | Required | Default |
|----------|-------------|----------|---------|
| `bucket_name` | S3 bucket for state (must be unique) | ✅ | - |
| `ecr_name` | ECR repository name | ✅ | - |
| `vpc_cidr_block` | VPC CIDR block | ✅ | `10.0.0.0/16` |
| `scan_on_push` | Enable ECR vulnerability scanning | ❌ | `true` |

### Environment Variables
```bash
export AWS_REGION=eu-central-1
export AWS_PROFILE=your-profile
export TF_VAR_bucket_name="your-unique-bucket-name"
```

## 🛠️ Common Operations

```bash
# View infrastructure
terraform show
terraform state list

# Make changes
terraform plan
terraform apply

# Use ECR repository
ECR_URL=$(terraform output -raw ecr_repository_url)
aws ecr get-login-password --region eu-central-1 | docker login --username AWS --password-stdin $ECR_URL
docker push $ECR_URL:latest

# Cleanup
terraform destroy
```

## 🚨 Troubleshooting

| Issue | Solution |
|-------|----------|
| S3 bucket already exists | Use unique bucket name with random suffix |
| State lock issues | `terraform force-unlock LOCK_ID` |
| AWS permission errors | Check IAM permissions and credentials |

For detailed troubleshooting, see individual module documentation.

## 🔒 Security Highlights

- ✅ **State Security**: Encrypted S3 storage with DynamoDB locking
- ✅ **Network Security**: Public/private subnet separation
- ✅ **Container Security**: ECR vulnerability scanning and lifecycle policies

## 🎯 Next Steps

After deployment, consider:
- Adding monitoring with CloudWatch
- Implementing CI/CD pipelines
- Adding NAT Gateways for private subnet internet access
- Setting up VPC endpoints for AWS services

For detailed implementation guides, refer to the individual module documentation linked above.

---

**� For comprehensive documentation, configuration examples, and advanced usage, please refer to the module-specific README files.**