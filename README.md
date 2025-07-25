# GoIT Microservice Kubernetes Project 🚀

Complete AWS microservice infrastructure with CI/CD, monitoring, and auto-scaling capabilities. This project implements a production-ready Kubernetes environment on AWS using Infrastructure as Code principles.

## 🏗️ Project Structure

```
├── DEPLOYMENT-GUIDE.md            # Complete deployment and configuration guide
├── deploy.sh                      # Complete infrastructure deployment
├── validate.sh                    # Comprehensive validation script
├── cleanup.sh                     # Safe cleanup of all resources
├── infra-backend/                  # S3 + DynamoDB for Terraform state
├── main-infra/                     # VPC + EKS + RDS + ECR + Services
├── django_app/                     # Django application with Dockerfile
│   ├── Dockerfile                  # Container build configuration
│   └── Jenkinsfile                 # CI/CD pipeline definition
├── jenkins/                        # Jenkins configuration
│   └── ManualDeploy.Jenkinsfile    # Manual deployment pipeline
├── charts/django-app/              # Helm chart for Django deployment
└── modules/                        # Reusable Terraform modules
    ├── vpc/                        # Virtual Private Cloud
    ├── ecr/                        # Elastic Container Registry
    ├── eks/                        # Elastic Kubernetes Service
    ├── rds/                        # PostgreSQL Database
    ├── jenkins/                    # Jenkins CI/CD
    ├── argo_cd/                    # Argo CD GitOps
    ├── monitoring/                 # Prometheus + Grafana
    └── s3-backend/                 # S3 backend storage
```

## 🎯 Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                                AWS Cloud Infrastructure                          │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                 │
│  ┌─────────────────┐    ┌─────────────────────────────────────────────────────┐ │
│  │  infra-backend  │    │                main-infra                          │ │
│  │                 │    │                                                     │ │
│  │ • S3 Bucket     │◄───┤ ┌─────────────┐ ┌─────────────┐ ┌─────────────────┐│ │
│  │ • DynamoDB      │    │ │     VPC     │ │    ECR      │ │   EKS Cluster   ││ │
│  │ • Terraform    │    │ │             │ │             │ │                 ││ │
│  │   State Store   │    │ │ Public/     │ │ Django      │ │ ┌─────────────┐ ││ │
│  └─────────────────┘    │ │ Private     │ │ Images      │ │ │   Jenkins   │ ││ │
│                         │ │ Subnets     │ │             │ │ │   CI/CD     │ ││ │
│                         │ └─────────────┘ └─────────────┘ │ └─────────────┘ ││ │
│                         │                                 │                 ││ │
│                         │ ┌─────────────┐ ┌─────────────┐ │ ┌─────────────┐ ││ │
│                         │ │     RDS     │ │   Argo CD   │ │ │  Django     │ ││ │
│                         │ │ PostgreSQL  │ │   GitOps    │ │ │  App Pods   │ ││ │
│                         │ │  Database   │ │             │ │ │  (2-6 HPA)  │ ││ │
│                         │ └─────────────┘ └─────────────┘ │ └─────────────┘ ││ │
│                         │                                 │                 ││ │
│                         │ ┌─────────────────────────────┐ │ ┌─────────────┐ ││ │
│                         │ │        Monitoring           │ │ │ PostgreSQL  │ ││ │
│                         │ │  • Prometheus (Metrics)     │ │ │   Pods      │ ││ │
│                         │ │  • Grafana (Dashboards)    │ │ │             │ ││ │
│                         │ │  • Alertmanager (Alerts)   │ │ └─────────────┘ ││ │
│                         │ └─────────────────────────────┘ └─────────────────┘│ │
│                         └─────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────────┘
```

## ✨ Complete Feature Set

### 🏗️ Infrastructure Components
- **VPC**: Secure network with public/private subnets across 3 AZs
- **EKS**: Managed Kubernetes cluster with auto-scaling node groups
- **RDS**: PostgreSQL database with multi-AZ deployment
- **ECR**: Private Docker registry for application images
- **S3**: Terraform state storage with encryption
- **DynamoDB**: State locking for concurrent deployments

### 🔄 CI/CD Pipeline
- **Jenkins**: Automated build and deployment pipelines
  - Integration with ECR for image builds
  - Automated testing and security scanning
  - Multi-environment deployment support
- **Argo CD**: GitOps continuous deployment
  - Declarative application management
  - Automatic synchronization with Git repository
  - Rollback capabilities and health monitoring

### 📊 Monitoring & Observability
- **Prometheus**: Metrics collection and storage
  - Kubernetes cluster metrics
  - Application performance metrics
  - Custom business metrics
- **Grafana**: Visualization and dashboards
  - Pre-configured Kubernetes dashboards
  - Custom application dashboards
  - Alert visualization
- **Alertmanager**: Alert routing and management
  - Integration with Slack, email, PagerDuty
  - Smart alert grouping and routing

![Grafana Prometheus Monitoring](screenshots/grafana%20prometheus%20monitoring.png)
*Grafana dashboard showing comprehensive monitoring with Prometheus metrics*

### 🔧 Application Features
- **Django Application**: Production-ready web application
  - Health checks and readiness probes
  - Environment-based configuration
  - Database migrations automation
- **Horizontal Pod Autoscaler**: Smart auto-scaling (2-6 pods)
- **Persistent Storage**: Database data persistence
- **Load Balancing**: Traffic distribution across pods

![Running Django App](screenshots/running%20django%20app.png)
*Django application successfully running in Kubernetes with LoadBalancer access*

### 🛡️ Security Features
- **IAM Roles**: Least privilege access control
- **Security Groups**: Network traffic filtering
- **VPC Isolation**: Network segmentation
- **Encrypted Storage**: Data encryption at rest
- **Secret Management**: Kubernetes secrets for sensitive data
- **Database Migrations**: Automatic migrations with init container
- **Health Checks**: Application and database connectivity endpoints

### ✅ CI/CD Pipeline
- **Jenkins**: Automated build and deployment pipeline with Kubernetes agents
- **Kaniko**: Container image building in Kubernetes without Docker daemon
- **Amazon ECR**: Docker image registry with automated pushes
- **Argo CD**: GitOps continuous deployment with automatic synchronization
- **Git Integration**: Automatic Helm chart updates with image tags
- **Pipeline Triggers**: GitHub webhook integration for automated builds

### ✅ Production Ready Features
- **Resource Limits**: CPU and memory requests/limits for proper scheduling
- **Auto-scaling**: Horizontal scaling based on CPU utilization
- **Health Checks**: Kubernetes readiness and liveness probes
- **Rolling Updates**: Zero-downtime deployments
- **Infrastructure as Code**: Complete Terraform automation
- **GitOps**: Declarative deployments with Argo CD

## 🚀 Quick Start

### Prerequisites
- AWS CLI configured with appropriate permissions
- Terraform >= 1.0
- kubectl
- Helm >= 3.0
- Docker

### Deployment Options

#### Option 1: Complete Infrastructure Deployment
```bash
# Deploy complete infrastructure with CI/CD, monitoring, and Django app
./deploy.sh
```

#### Option 2: Manual Step-by-Step Deployment
```bash
# 1. Deploy backend infrastructure
cd infra-backend
terraform init && terraform apply

# 2. Deploy main infrastructure
cd ../main-infra
terraform init && terraform apply

# 3. Configure kubectl
aws eks update-kubeconfig --region eu-central-1 --name eks-cluster-demo
```

#### Validation
```bash
# Validate complete deployment
./validate.sh
```

## 📖 Documentation

### Complete Deployment Guide
For detailed step-by-step instructions on configuring Jenkins build jobs and Argo CD sync:

📋 **[DEPLOYMENT-GUIDE.md](DEPLOYMENT-GUIDE.md)** - Complete deployment and configuration guide

This comprehensive guide covers:
- Jenkins CI/CD pipeline configuration
- Argo CD GitOps setup and sync process
- Manual deployment procedures
- Troubleshooting and monitoring

## 🔧 Service Access

### Development Access (Port Forwarding)
```bash
# Jenkins CI/CD
kubectl port-forward svc/jenkins 8080:8080 -n jenkins
# Access: http://localhost:8080

# Argo CD GitOps
kubectl port-forward svc/argocd-server 8081:443 -n argocd
# Access: https://localhost:8081

# Grafana Monitoring
kubectl port-forward svc/prometheus-grafana 3000:80 -n monitoring
# Access: http://localhost:3000

# Prometheus Metrics
kubectl port-forward svc/prometheus-kube-prometheus-prometheus 9090:9090 -n monitoring
# Access: http://localhost:9090

# Django Application
kubectl port-forward svc/django-app 8000:80 -n default
# Access: http://localhost:8000
```

### AWS Console Access
The EKS cluster is automatically configured with access permissions for the current AWS user. After deployment, you can access the EKS cluster directly in the AWS Console:

```bash
# Get EKS Console URL
terraform output -raw eks_console_url

# Current user with access
terraform output -raw current_user_arn
```

**Note**: The deployment automatically creates EKS access entries and policies for the current AWS user, allowing you to view and manage Kubernetes resources directly in the AWS EKS console.

### Service Credentials
```bash
# Jenkins admin password
kubectl get secret jenkins -n jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode

# Argo CD admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Grafana credentials
# Username: admin
# Password: admin123AWS
```

### Test Application

```bash
# Run comprehensive tests
./test-app.sh
```

### Access Services

#### Django Application
```bash
#### Django Application
```bash
# Get LoadBalancer URL
kubectl get service django-app-django -n django-app

# Test endpoints
curl http://<loadbalancer-url>/          # Root endpoint
curl http://<loadbalancer-url>/health/   # Health check with DB status
curl http://<loadbalancer-url>/admin/    # Django admin
```

#### Argo CD
```bash
# Get Argo CD URL
kubectl get service argocd-server -n argocd

# Get admin password
kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath='{.data.password}' | base64 -d
```

## 🧹 Cleanup

When you're finished with the infrastructure, you can clean it up safely:

```bash
# Remove all resources (infrastructure and applications)
./cleanup.sh
```

Or manually:
```bash
# Destroy main infrastructure first
cd main-infra
terraform destroy

# Then destroy backend if needed
cd ../infra-backend
terraform destroy
```

## Key Benefits

✅ **Automated CI/CD**: Complete Jenkins and Argo CD pipeline  
✅ **GitOps Workflow**: Declarative deployments from Git  
✅ **Production Ready**: Auto-scaling, health checks, monitoring  
✅ **Secure by Default**: Encrypted storage, private subnets, IAM roles  
✅ **Infrastructure as Code**: Complete Terraform automation  

## 📚 Documentation

### Core Documentation
- **[DEPLOYMENT-GUIDE.md](DEPLOYMENT-GUIDE.md)** - Complete deployment and configuration guide
- [Backend Infrastructure](./infra-backend/README.md) - S3 + DynamoDB setup
- [Main Infrastructure](./main-infra/README.md) - VPC + EKS + ECR setup

### Module Documentation

| Module | Purpose | Documentation |
|--------|---------|---------------|
| **[S3 Backend](./modules/s3-backend/README.md)** | Remote state storage and locking | Complete setup guide, security considerations |
| **[VPC](./modules/vpc/README.md)** | Network infrastructure and subnets | Architecture diagrams, use cases, NAT Gateway options |
| **[ECR](./modules/ecr/README.md)** | Container registry with security | Docker integration, lifecycle policies |
| **[EKS](./modules/eks/README.md)** | Kubernetes cluster management | Cluster setup, node groups, auto-scaling configuration |
| **[RDS](./modules/rds/README.md)** | Universal RDS/Aurora database module | Aurora and Standard RDS support, parameter groups, security |
| **[Jenkins](./modules/jenkins/README.md)** | CI/CD automation platform | Pipeline configuration, plugins, security |
| **[Argo CD](./modules/argo_cd/README.md)** | GitOps continuous deployment | Application management, sync policies |
| **[Monitoring](./modules/monitoring/README.md)** | Prometheus and Grafana stack | Metrics, dashboards, alerting |

## ⚙️ Configuration

### Key Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `aws_region` | AWS region for resources | `eu-central-1` |
| `bucket_name` | S3 bucket for state (must be unique) | `terraform-state-bucket-127214174194` |
| `table_name` | DynamoDB table for state locking | `terraform-locks` |
| `vpc_cidr_block` | VPC CIDR block | `10.0.0.0/16` |
| `cluster_name` | EKS cluster name | `eks-cluster-demo` |

## 🔐 Security Features

- ✅ **State Security**: Encrypted S3 storage with DynamoDB locking
- ✅ **Network Security**: Public/private subnet separation with NAT Gateway
- ✅ **Container Security**: ECR vulnerability scanning and lifecycle policies
- ✅ **Kubernetes Security**: EKS IAM integration and RBAC
- ✅ **CI/CD Security**: IRSA for service accounts, secret management
- ✅ **Access Control**: S3 bucket public access blocked by default

## 🎯 CI/CD Pipeline

### Pipeline Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Git Commit    │───▶│    Jenkins      │───▶│   Amazon ECR    │───▶│    Argo CD      │
│                 │    │                 │    │                 │    │                 │
│ • Source Code   │    │ • Build Image   │    │ • Store Image   │    │ • Deploy App    │
│ • Jenkinsfile   │    │ • Push to ECR   │    │ • Tagged Images │    │ • Auto Sync     │
│ • Dockerfile    │    │ • Update Chart  │    │ • Latest Tag    │    │ • Health Check  │
└─────────────────┘    └─────────────────┘    └─────────────────┘    └─────────────────┘
                                │                                               │
                                ▼                                               ▼
                       ┌─────────────────┐                            ┌─────────────────┐
                       │  Git Repository │◄───────────────────────────│  EKS Cluster    │
                       │                 │                            │                 │
                       │ • Helm Charts   │                            │ • Django Pods   │
                       │ • Updated Tags  │                            │ • PostgreSQL    │
                       │ • values.yaml   │                            │ • Services      │
                       └─────────────────┘                            └─────────────────┘
```

### Pipeline Features

1. **Automated Builds** → Jenkins builds Docker images on every commit
2. **Container Registry** → Images pushed to AWS ECR with unique tags
3. **GitOps Updates** → Helm chart values automatically updated
4. **Continuous Deployment** → Argo CD syncs changes to cluster
5. **Health Monitoring** → Application health checks and rollback capabilities

### Pipeline in Action

![Jenkins Successful Image Build](screenshots/jenkins%20successful%20image%20build.png)
*Jenkins CI/CD pipeline successfully building and pushing Docker images to ECR*

![Argo CD Successful Sync](screenshots/argo%20cd%20successful%20sync.png)
*Argo CD GitOps platform automatically syncing applications to Kubernetes cluster*

## 🚀 Getting Started

1. **Clone the repository**
2. **Review [DEPLOYMENT-GUIDE.md](DEPLOYMENT-GUIDE.md)** for detailed instructions
3. **Deploy infrastructure** with `./deploy.sh`
4. **Validate deployment** with `./validate.sh`
5. **Configure Jenkins** pipeline for your Django application
6. **Set up Argo CD** GitOps workflow
7. **Deploy your application** and enjoy automated CI/CD!

## 📸 Project Screenshots

### CI/CD Pipeline in Action
![Jenkins Successful Image Build](screenshots/jenkins%20successful%20image%20build.png)
*Jenkins CI/CD pipeline successfully building and pushing Docker images to Amazon ECR*

![Argo CD Successful Sync](screenshots/argo%20cd%20successful%20sync.png)
*Argo CD GitOps platform automatically synchronizing applications to Kubernetes cluster*

### Application & Monitoring
![Running Django App](screenshots/running%20django%20app.png)
*Django application successfully deployed and accessible via AWS LoadBalancer*

![Grafana Prometheus Monitoring](screenshots/grafana%20prometheus%20monitoring.png)
*Comprehensive monitoring dashboard with Prometheus metrics and Grafana visualizations*
```

#### Jenkins
```bash
# Get Jenkins URL
kubectl get service jenkins -n jenkins
# Default: admin/admin123
```

#### Argo CD
```bash
# Get Argo CD URL
kubectl get service argocd-server -n argocd

# Get admin password
kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath='{.data.password}' | base64 -d
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
- [RDS Module](./modules/rds/README.md) - Universal RDS/Aurora database module
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
| **[RDS](./modules/rds/README.md)** | Universal RDS/Aurora database module | Aurora and Standard RDS support, parameter groups, security |

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

## CI/CD Pipeline

### Pipeline Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Git Commit    │───▶│    Jenkins      │───▶│   Amazon ECR    │───▶│    Argo CD      │
│                 │    │                 │    │                 │    │                 │
│ • Source Code   │    │ • Build Image   │    │ • Store Image   │    │ • Deploy App    │
│ • Jenkinsfile   │    │ • Push to ECR   │    │ • Tagged Images │    │ • Auto Sync     │
│ • Dockerfile    │    │ • Update Chart  │    │ • Latest Tag    │    │ • Health Check  │
└─────────────────┘    └─────────────────┘    └─────────────────┘    └─────────────────┘
                                │                                               │
                                ▼                                               ▼
                       ┌─────────────────┐                            ┌─────────────────┐
                       │  Git Repository │◄───────────────────────────│  EKS Cluster    │
                       │                 │                            │                 │
                       │ • Helm Charts   │                            │ • Django Pods   │
                       │ • Updated Tags  │                            │ • PostgreSQL    │
                       │ • values.yaml   │                            │ • Services      │
                       └─────────────────┘                            └─────────────────┘
```

### Pipeline Steps

1. **Developer commits code** → Triggers Jenkins webhook
2. **Jenkins builds Docker image** → Uses Kaniko in Kubernetes
3. **Image pushed to ECR** → With unique tag and 'latest'
4. **Helm chart updated** → New image tag pushed to Git
5. **Argo CD detects changes** → Automatically syncs to cluster
6. **Application deployed** → Zero-downtime rolling update

### Getting Started with CI/CD

```bash
# 1. Deploy complete infrastructure
./deploy-ci-cd.sh

# 2. Configure Jenkins pipeline
./configure-jenkins.sh

# 3. Test the pipeline
./test-ci-cd.sh
```

For detailed CI/CD documentation, see [CI-CD-DOCUMENTATION.md](./CI-CD-DOCUMENTATION.md)