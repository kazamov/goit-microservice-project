# GoIT Microservice Infrastructure Project

A Terraform-based Infrastructure as Code (IaC) project for deploying microservice applications on AWS with modular architecture and remote state management.

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         AWS Account                             │
│                                                                 │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  │
│  │   S3 Backend    │  │      VPC        │  │      ECR        │  │
│  │                 │  │                 │  │                 │  │
│  │ • State Storage │  │ • Public Subnet │  │ • Docker Images │  │
│  │ • DynamoDB Lock │  │ • Private Subnet│  │ • Vulnerability │  │
│  │ • Versioning    │  │ • Internet GW   │  │   Scanning      │  │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

## 📁 Project Structure

```
goit-microservice-project/
├── README.md                         # Project overview (this file)
├── main.tf                          # Main configuration
├── backend.tf                       # Backend configuration
├── outputs.tf                       # Root outputs
├── examples/                        # Example configurations
│   └── ecr-lifecycle-policy.json
└── modules/                         # Terraform modules
    ├── s3-backend/                  # Remote state backend
    │   └── README.md               # 📖 S3 Backend Documentation
    ├── vpc/                         # VPC networking
    │   └── README.md               # 📖 VPC Documentation
    └── ecr/                         # Container registry
        └── README.md               # 📖 ECR Documentation
```

## 🚀 Quick Start

### Prerequisites
- AWS CLI configured with appropriate credentials
- Terraform installed (version 1.0+)
- Required AWS permissions (S3, DynamoDB, VPC, ECR, IAM)

### Setup Steps

1. **Clone and configure**
   ```bash
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