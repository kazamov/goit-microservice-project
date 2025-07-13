# GoIT Microservice Kubernetes Project

This project provides a complete AWS infrastructure setup for deploying Django microservices on Kubernetes using Terraform, with ECR for container registry and Helm for application deployment.

## Project Structure

```
├── deploy-backend.sh     # Automated backend deployment script
├── deploy-main.sh        # Main infrastructure deployment script  
├── deploy-app.sh         # Django application deployment script
├── cleanup-app.sh        # Application cleanup script
├── validate-backend.sh   # Configuration validation script
├── infra-backend/        # Backend infrastructure (S3 + DynamoDB)
├── main-infra/          # Main application infrastructure (VPC + ECR + EKS)
├── django_app/          # Django application with Dockerfile
├── charts/              # Helm charts for Kubernetes deployment
│   └── django-app/      # Django Helm chart with HPA, ConfigMap, Service
└── modules/             # Reusable Terraform modules
    ├── ecr/            # Elastic Container Registry module
    ├── eks/            # Elastic Kubernetes Service module
    ├── s3-backend/     # S3 backend storage module
    └── vpc/            # Virtual Private Cloud module
```

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  infra-backend  │    │   main-infra    │    │  EKS + Django   │
│                 │    │                 │    │                 │
│ • S3 Bucket     │◄───┤ • VPC           │◄───┤ • EKS Cluster   │
│ • DynamoDB      │    │ • ECR Registry  │    │ • Django Pods   │
│ • Local State   │    │ • Remote State  │    │ • HPA (2-6)     │
└─────────────────┘    └─────────────────┘    │ • LoadBalancer  │
                                               └─────────────────┘
```

## Features Implemented

### ✅ Kubernetes Infrastructure
- **EKS Cluster**: Managed Kubernetes cluster in existing VPC
- **ECR Registry**: Docker image storage for Django application
- **VPC Integration**: Reuses existing network infrastructure

### ✅ Django Application Deployment
- **Helm Chart**: Complete chart with deployment, service, HPA, configmap
- **PostgreSQL Database**: Bitnami PostgreSQL 17.5 chart integration with persistent storage
- **Horizontal Pod Autoscaler**: Auto-scaling from 2-6 pods based on CPU (>70%)
- **LoadBalancer Service**: External access to Django application
- **ConfigMap**: Environment variables management (moved from docker-compose)
- **Database Migrations**: Automatic migrations with init container
- **Health Checks**: Application and database connectivity endpoints

### ✅ Production Ready Features
- **Resource Limits**: CPU and memory requests/limits for proper scheduling
- **Auto-scaling**: Horizontal scaling based on CPU utilization
- **Health Checks**: Kubernetes readiness and liveness probes
- **Rolling Updates**: Zero-downtime deployments

## Quick Start

### 1. Deploy Infrastructure

```bash
# Validate configuration
./validate-backend.sh

# Deploy backend (S3 + DynamoDB)
./deploy-backend.sh

# Deploy main infrastructure (VPC + ECR + EKS)
./deploy-main.sh
```

### 2. Deploy Django Application

```bash
# Build Docker image, push to ECR, and deploy with Helm
./deploy-app.sh
```

### 3. Test Application

```bash
# Run comprehensive tests
./test-app.sh
```

### 4. Access Application

```bash
# Get LoadBalancer URL
kubectl get service django-app-django

# Test endpoints
curl http://<loadbalancer-url>/          # Root endpoint
curl http://<loadbalancer-url>/health/   # Health check with DB status
curl http://<loadbalancer-url>/admin/    # Django admin
```

### 4. Monitor Scaling

```bash
# Check HPA status
kubectl get hpa
kubectl describe hpa django-app-django-hpa

# Check pod scaling
kubectl get pods -w

# Monitor PostgreSQL
kubectl logs -l app.kubernetes.io/name=postgresql
```

### 5. Cleanup (Optional)

```bash
# Remove Django application
./cleanup-app.sh

# Destroy infrastructure
cd main-infra && terraform destroy
cd ../infra-backend && terraform destroy
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
- [EKS Module](./modules/eks/README.md) - Kubernetes cluster module
- [S3 Backend Module](./modules/s3-backend/README.md) - State storage module
- [VPC Module](./modules/vpc/README.md) - Networking module

## Module Documentation

Each module includes comprehensive documentation with usage examples and best practices:

| Module | Purpose | Documentation |
|--------|---------|---------------|
| **[S3 Backend](./modules/s3-backend/README.md)** | Remote state storage and locking | Complete setup guide, security considerations |
| **[VPC](./modules/vpc/README.md)** | Network infrastructure and subnets | Architecture diagrams, use cases, NAT Gateway options |
| **[ECR](./modules/ecr/README.md)** | Container registry with security | Docker integration, lifecycle policies |
| **[EKS](./modules/eks/README.md)** | Kubernetes cluster management | Cluster setup, node groups, auto-scaling configuration |

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

# Deploy main infrastructure (VPC + ECR)
cd main-infra
terraform init
terraform apply

# Deploy EKS cluster (optional)
# Add EKS module to main-infra/main.tf first
terraform plan
terraform apply
```

### EKS Deployment Example

To add EKS to your infrastructure, update `main-infra/main.tf`:

```hcl
module "eks" {
  source       = "../modules/eks"
  cluster_name = "my-eks-cluster"
  subnet_ids   = module.vpc.private_subnets
  
  instance_type = "t3.medium"
  desired_size  = 2
  min_size      = 1
  max_size      = 4
}
```

### Container Workflow

```bash
# Build and push to ECR
ECR_URL=$(terraform output -raw ecr_repository_url)
aws ecr get-login-password --region eu-central-1 | docker login --username AWS --password-stdin $ECR_URL
docker build -t my-app .
docker tag my-app:latest $ECR_URL:latest
docker push $ECR_URL:latest

# Deploy to EKS
kubectl apply -f k8s-manifests/
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| S3 bucket already exists | Update `bucket_name` variable with unique suffix |
| State lock issues | `terraform force-unlock LOCK_ID` |
| AWS permission errors | Check IAM permissions and AWS credentials |
| Terraform validation fails | Run `./validate-backend.sh` for detailed errors |

## Security Features

## Security Features

- ✅ **State Security**: Encrypted S3 storage with DynamoDB locking
- ✅ **Network Security**: Public/private subnet separation with optional NAT Gateway
- ✅ **Container Security**: ECR vulnerability scanning and lifecycle policies
- ✅ **Kubernetes Security**: EKS IAM integration and RBAC
- ✅ **Access Control**: S3 bucket public access blocked by default

## Next Steps

After deployment, consider:

### Infrastructure Enhancements
- Adding monitoring with CloudWatch and Container Insights
- Implementing CI/CD pipelines with CodePipeline
- Adding NAT Gateways for private subnet internet access
- Setting up VPC endpoints for AWS services

### Kubernetes Operations
- Deploy EKS cluster using the provided module
- Configure kubectl and AWS Load Balancer Controller
- Set up Horizontal Pod Autoscaler (HPA)
- Implement cluster monitoring and logging
- Configure persistent storage with EBS CSI driver

### Application Deployment
- Build container images and push to ECR
- Create Kubernetes manifests for your applications
- Set up ingress controllers for traffic management
- Implement GitOps workflows with ArgoCD or Flux

---

**For comprehensive documentation and advanced configuration, refer to the module-specific README files.**