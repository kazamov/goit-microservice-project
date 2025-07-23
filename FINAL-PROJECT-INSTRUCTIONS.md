# Step-by-Step Final Project Implementation Guide

## Technical Requirements

- **Infrastructure**: AWS using Terraform
- **Components**: VPC, EKS, RDS, ECR, Jenkins, Argo CD, Prometheus, Grafana
- **Additional Services**: Django application, PostgreSQL, monitoring

---

## Prerequisites

### 1. Required Tools
```bash
# Check installations
terraform --version  # >= 1.0
aws --version        # AWS CLI v2
kubectl version      # Kubernetes CLI
helm version         # Helm package manager
docker --version     # Docker for image builds
```

### 2. AWS Configuration
```bash
# Configure AWS credentials
aws configure
# or export environment variables
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="eu-central-1"
```

### 3. AWS Permissions Verification
Ensure you have permissions to create:
- VPC, Subnets, Internet Gateway, Route Tables
- EKS Cluster, Node Groups
- RDS (PostgreSQL)
- ECR Repository
- IAM Roles and Policies
- S3 Buckets, DynamoDB Tables

---

## Implementation Stages

### Stage 1: Environment Preparation

#### 1.1 Project Cloning and Initialization
```bash
cd /Users/zakir/Git/goit-microservice-project
```

#### 1.2 Configuration Verification
```bash
# Check variables in variables.tf
cat main-infra/variables.tf
cat infra-backend/variables.tf
```

#### 1.3 Terraform Configuration Validation
```bash
# For backend infrastructure
cd infra-backend
terraform validate

# For main infrastructure
cd ../main-infra
terraform validate
```

### Stage 2: Backend Infrastructure Deployment

#### 2.1 Creating S3 and DynamoDB for Terraform state
```bash
cd infra-backend
terraform init
terraform plan
terraform apply
```

#### 2.2 Verifying Created Resources
```bash
# Check S3 bucket
aws s3 ls | grep terraform-state

# Check DynamoDB table
aws dynamodb list-tables | grep terraform-locks
```

### Stage 3: Main Infrastructure Deployment

#### 3.1 Main Infrastructure Initialization
```bash
cd ../main-infra
terraform init
```

#### 3.2 Planning and Application
```bash
# Detailed deployment plan
terraform plan -out=tfplan

# Apply changes
terraform apply tfplan
```

#### 3.3 Verifying Created Resources
```bash
# VPC
aws ec2 describe-vpcs --filters "Name=tag:Name,Values=main-vpc"

# EKS Cluster
aws eks describe-cluster --name eks-cluster-demo

# RDS
aws rds describe-db-instances --db-instance-identifier myapp-db

# ECR
aws ecr describe-repositories --repository-names django_app
```

### Stage 4: EKS Access Configuration

#### 4.1 Updating kubeconfig
```bash
aws eks update-kubeconfig --region eu-central-1 --name eks-cluster-demo
```

#### 4.2 Connection Verification
```bash
kubectl get nodes
kubectl get namespaces
```

### Stage 5: Service Verification

#### 5.1 Jenkins
```bash
# Check status
kubectl get all -n jenkins

# Get Jenkins password
kubectl get secret jenkins -n jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode

# Port forwarding for access
kubectl port-forward svc/jenkins 8080:8080 -n jenkins
```
**Access**: http://localhost:8080
- Username: admin
- Password: (obtained from command above)

#### 5.2 Argo CD
```bash
# Check status
kubectl get all -n argocd

# Get Argo CD password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Port forwarding for access
kubectl port-forward svc/argocd-server 8081:443 -n argocd
```
**Access**: https://localhost:8081
- Username: admin
- Password: (obtained from command above)

#### 5.3 Prometheus
```bash
# Check status
kubectl get all -n monitoring

# Port forwarding for access
kubectl port-forward svc/prometheus-kube-prometheus-prometheus 9090:9090 -n monitoring
```
**Access**: http://localhost:9090

#### 5.4 Grafana
```bash
# Port forwarding for access
kubectl port-forward svc/prometheus-grafana 3000:80 -n monitoring
```
**Access**: http://localhost:3000
- Username: admin
- Password: admin123AWS

### Stage 6: Django Application Deployment

#### 6.1 Building and Pushing Docker Image
```bash
# Get ECR login
aws ecr get-login-password --region eu-central-1 | docker login --username AWS --password-stdin $(aws sts get-caller-identity --query Account --output text).dkr.ecr.eu-central-1.amazonaws.com

# Build image
cd django_app
docker build -t django_app .

# Tag for ECR
docker tag django_app:latest $(aws sts get-caller-identity --query Account --output text).dkr.ecr.eu-central-1.amazonaws.com/django_app:latest

# Push to ECR
docker push $(aws sts get-caller-identity --query Account --output text).dkr.ecr.eu-central-1.amazonaws.com/django_app:latest
```

#### 6.2 Deployment via Helm
```bash
cd ../charts/django-app

# Update values.yaml with current data
# Install application
helm install django-app . -n default

# Check status
kubectl get all -n default
```

### Stage 7: CI/CD Configuration

#### 7.1 Jenkins Pipeline Configuration
1. Open Jenkins (http://localhost:8080)
2. Create new Pipeline job
3. Specify Git repository
4. Configure Jenkinsfile from django_app/

#### 7.2 Argo CD Application Configuration
1. Open Argo CD (https://localhost:8081)
2. Create Application:
   - Repository URL: Git repository URL
   - Path: charts/django-app
   - Destination: Kubernetes cluster
   - Namespace: default

### Stage 8: Monitoring Verification

#### 8.1 Grafana Dashboards
1. Open Grafana (http://localhost:3000)
2. Check pre-installed dashboards:
   - Kubernetes / Compute Resources / Cluster
   - Kubernetes / Compute Resources / Namespace (Pods)
   - Node Exporter / Nodes

#### 8.2 Prometheus Targets
1. Open Prometheus (http://localhost:9090)
2. Navigate to Status → Targets
3. Verify all targets are in UP status

#### 8.3 Application Metrics
```bash
# Verify Django app exports metrics
kubectl port-forward svc/django-app 8000:80 -n default
curl http://localhost:8000/metrics
```

### Stage 9: Auto-scaling Testing

#### 9.1 HPA Verification
```bash
kubectl get hpa -n default
kubectl describe hpa django-app-hpa -n default
```

#### 9.2 Load Testing
```bash
# Generate load
kubectl run -i --tty load-generator --rm --image=busybox --restart=Never -- /bin/sh

# In container
while true; do wget -q -O- http://django-app/; done
```

#### 9.3 Scaling Observation
```bash
# Monitor changes
kubectl get pods -n default -w
kubectl top pods -n default
```

---

## Assessment Criteria and Verification

### 1. Correct Architecture Environment Created (20 points)

**Verification:**
```bash
# VPC and network
kubectl get nodes -o wide
aws ec2 describe-vpcs --filters "Name=tag:Name,Values=main-vpc"

# EKS cluster
kubectl cluster-info
kubectl get namespaces
```

**Criteria:**
- ✅ VPC with public and private subnets
- ✅ EKS cluster functional
- ✅ Nodes connected and ready
- ✅ All services deployed in correct namespaces

### 2. Security Configured via VPC, IAM, Security Groups (20 points)

**Verification:**
```bash
# Security Groups
aws ec2 describe-security-groups --filters "Name=group-name,Values=*eks*"

# IAM roles
aws iam list-roles --query 'Roles[?contains(RoleName, `eks`) || contains(RoleName, `jenkins`) || contains(RoleName, `argocd`)]'

# Network policies (if configured)
kubectl get networkpolicies --all-namespaces
```

**Criteria:**
- ✅ Correct IAM roles for services
- ✅ Security Groups restrict traffic
- ✅ RDS in private subnets
- ✅ Correct RBAC configurations

### 3. Application Deployed in AWS with CI/CD (30 points)

**Verification:**
```bash
# Jenkins pipeline
kubectl logs -n jenkins deployment/jenkins

# Argo CD applications
kubectl get applications -n argocd

# Django application
kubectl get deployments,services,ingress -n default
curl http://django-app-service/health
```

**Criteria:**
- ✅ Jenkins successfully launched and configured
- ✅ Argo CD synchronizes applications
- ✅ Django application accessible
- ✅ Pipeline automatically deploys changes
- ✅ ECR contains application images

### 4. Monitoring and Auto-scaling Configured (20 points)

**Verification:**
```bash
# Prometheus metrics
kubectl get servicemonitors -n monitoring
curl http://prometheus:9090/api/v1/targets

# Grafana dashboards
kubectl get configmaps -n monitoring | grep dashboard

# HPA
kubectl get hpa -n default
kubectl top nodes
kubectl top pods -n default
```

**Criteria:**
- ✅ Prometheus collects metrics
- ✅ Grafana displays dashboards
- ✅ HPA configured and functional
- ✅ Alerting rules configured
- ✅ Application metrics available

### 5. Correct Documentation and Clarity (10 points)

**Verification:**
- ✅ README.md contains complete information
- ✅ Terraform code well-structured
- ✅ Code comments are clear
- ✅ Helm charts documented
- ✅ Scripts have explanations

---

## Quick Verification Commands

### Overall System Status
```bash
echo "=== EKS Cluster ==="
kubectl get nodes

echo "=== All Namespaces ==="
kubectl get pods --all-namespaces

echo "=== Services ==="
kubectl get svc --all-namespaces

echo "=== Persistent Volumes ==="
kubectl get pv,pvc --all-namespaces

echo "=== HPA Status ==="
kubectl get hpa --all-namespaces
```

### Component Status
```bash
echo "=== Jenkins ==="
kubectl get all -n jenkins

echo "=== Argo CD ==="
kubectl get all -n argocd

echo "=== Monitoring ==="
kubectl get all -n monitoring

echo "=== Django App ==="
kubectl get all -n default
```

### Diagnostic Logs
```bash
# Jenkins logs
kubectl logs -n jenkins deployment/jenkins --tail=100

# Argo CD logs
kubectl logs -n argocd deployment/argocd-server --tail=100

# Django app logs
kubectl logs -n default deployment/django-app --tail=100

# Prometheus logs
kubectl logs -n monitoring statefulset/prometheus-kube-prometheus-prometheus --tail=100
```

---

## Expected Results

After successfully completing all stages, you should have:

1. **AWS Infrastructure** with VPC, EKS, RDS, ECR
2. **Jenkins** for CI/CD pipelines
3. **Argo CD** for GitOps deployments
4. **Prometheus + Grafana** for monitoring
5. **Django application** with auto-scaling
6. **Secure network architecture**
7. **Automated deployment processes**

All services should be accessible via port-forward and function correctly.

---

## Troubleshooting

### Common Issues and Solutions

#### 1. EKS nodes not connecting
```bash
# Check IAM roles
aws iam get-role --role-name eksNodeInstanceRole

# Check security groups
aws ec2 describe-security-groups --group-ids sg-xxx
```

#### 2. Jenkins not starting
```bash
# Check PVC
kubectl get pvc -n jenkins

# Check logs
kubectl logs -n jenkins deployment/jenkins
```

#### 3. Prometheus not collecting metrics
```bash
# Check ServiceMonitors
kubectl get servicemonitors -n monitoring

# Check endpoints
kubectl get endpoints -n monitoring
```

#### 4. Django app unavailable
```bash
# Check ECR image
aws ecr list-images --repository-name django_app

# Check deployment
kubectl describe deployment django-app -n default
```
