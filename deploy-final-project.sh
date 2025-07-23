#!/bin/bash

# Quick Deploy Script for Final Project
# This script automates the complete deployment of the microservice infrastructure

set -e

echo "🚀 GoIT Microservice Project - Quick Deploy"
echo "==========================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print status
print_step() {
    echo -e "${BLUE}📋 Step $1: $2${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Function to check if command succeeded
check_command() {
    if [ $? -eq 0 ]; then
        print_success "$1"
    else
        print_error "$1 failed"
        exit 1
    fi
}

# Get project root directory
PROJECT_ROOT="/Users/zakir/Git/goit-microservice-project"
cd "$PROJECT_ROOT"

echo
print_step "1" "Checking Prerequisites"
echo "--------------------------------------"

# Check required tools
REQUIRED_TOOLS=("terraform" "aws" "kubectl" "helm" "docker")
for tool in "${REQUIRED_TOOLS[@]}"; do
    if command -v $tool &> /dev/null; then
        print_success "$tool is available"
    else
        print_error "$tool is NOT installed"
        exit 1
    fi
done

# Check AWS credentials
if aws sts get-caller-identity &> /dev/null; then
    AWS_ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
    AWS_REGION=$(aws configure get region || echo "eu-central-1")
    print_success "AWS credentials configured (Account: $AWS_ACCOUNT, Region: $AWS_REGION)"
else
    print_error "AWS credentials not configured"
    exit 1
fi

echo
print_step "2" "Deploying Backend Infrastructure"
echo "------------------------------------------------"

cd infra-backend

# Initialize and deploy backend
terraform init
check_command "Backend Terraform initialization"

terraform plan -out=backend.tfplan
check_command "Backend Terraform planning"

terraform apply -auto-approve backend.tfplan
check_command "Backend infrastructure deployment"

print_success "S3 backend and DynamoDB table created"

echo
print_step "3" "Deploying Main Infrastructure"
echo "---------------------------------------------"

cd ../main-infra

# Initialize main infrastructure
terraform init
check_command "Main Terraform initialization"

terraform plan -out=main.tfplan
check_command "Main Terraform planning"

terraform apply -auto-approve main.tfplan
check_command "Main infrastructure deployment"

print_success "VPC, EKS, RDS, ECR, Jenkins, Argo CD, and Monitoring deployed"

echo
print_step "4" "Configuring Kubernetes Access"
echo "---------------------------------------------"

# Update kubeconfig
aws eks update-kubeconfig --region $AWS_REGION --name eks-cluster-demo
check_command "Kubeconfig update"

# Wait for nodes to be ready
echo "Waiting for EKS nodes to be ready..."
kubectl wait --for=condition=Ready nodes --all --timeout=300s
check_command "EKS nodes ready"

echo
print_step "5" "Waiting for Services to Start"
echo "---------------------------------------------"

# Wait for Jenkins
echo "Waiting for Jenkins to be ready..."
kubectl wait --for=condition=available --timeout=600s deployment/jenkins -n jenkins
check_command "Jenkins deployment ready"

# Wait for Argo CD
echo "Waiting for Argo CD to be ready..."
kubectl wait --for=condition=available --timeout=600s deployment/argocd-server -n argocd
check_command "Argo CD deployment ready"

# Wait for Prometheus
echo "Waiting for Prometheus to be ready..."
kubectl wait --for=condition=ready --timeout=600s pod -l app.kubernetes.io/name=prometheus -n monitoring
check_command "Prometheus ready"

# Wait for Grafana
echo "Waiting for Grafana to be ready..."
kubectl wait --for=condition=available --timeout=600s deployment/prometheus-grafana -n monitoring
check_command "Grafana deployment ready"

echo
print_step "6" "Building and Pushing Django Application"
echo "-------------------------------------------------------"

cd ../django_app

# Get ECR login
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT.dkr.ecr.$AWS_REGION.amazonaws.com
check_command "ECR login"

# Build Docker image
docker build -t django_app .
check_command "Docker image build"

# Tag for ECR
docker tag django_app:latest $AWS_ACCOUNT.dkr.ecr.$AWS_REGION.amazonaws.com/django_app:latest
check_command "Docker image tagging"

# Push to ECR
docker push $AWS_ACCOUNT.dkr.ecr.$AWS_REGION.amazonaws.com/django_app:latest
check_command "Docker image push to ECR"

echo
print_step "7" "Deploying Django Application"
echo "--------------------------------------------"

cd ../charts/django-app

# Update image in values.yaml
sed -i.bak "s|repository: .*|repository: $AWS_ACCOUNT.dkr.ecr.$AWS_REGION.amazonaws.com/django_app|g" values.yaml
sed -i.bak "s|tag: .*|tag: latest|g" values.yaml

# Deploy using Helm
helm upgrade --install django-app . --namespace default --create-namespace \
    --set image.repository=$AWS_ACCOUNT.dkr.ecr.$AWS_REGION.amazonaws.com/django_app \
    --set image.tag=latest \
    --wait --timeout=300s
check_command "Django application deployment"

echo
print_step "8" "Getting Service Information"
echo "------------------------------------------"

echo
echo "🔐 Service Credentials:"
echo "======================"

# Jenkins password
echo "Jenkins Admin Password:"
kubectl get secret jenkins -n jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode
echo

# Argo CD password
echo "Argo CD Admin Password:"
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
echo

# Grafana password (from our configuration)
echo "Grafana Admin Password: admin123AWS"
echo

echo
echo "🌐 Service Access URLs:"
echo "======================"
echo "Jenkins:    http://localhost:8080 (kubectl port-forward svc/jenkins 8080:8080 -n jenkins)"
echo "Argo CD:    https://localhost:8081 (kubectl port-forward svc/argocd-server 8081:443 -n argocd)"
echo "Grafana:    http://localhost:3000 (kubectl port-forward svc/prometheus-grafana 3000:80 -n monitoring)"
echo "Prometheus: http://localhost:9090 (kubectl port-forward svc/prometheus-kube-prometheus-prometheus 9090:9090 -n monitoring)"

echo
echo "🖥️  AWS Console Access:"
echo "======================"
# Get EKS console URL from Terraform output
cd ../main-infra
EKS_CONSOLE_URL=$(terraform output -raw eks_console_url 2>/dev/null || echo "EKS Console URL not available")
CURRENT_USER=$(terraform output -raw current_user_arn 2>/dev/null || echo "Current user ARN not available")
cd - > /dev/null  # Return to previous directory quietly

echo "EKS Cluster Console: $EKS_CONSOLE_URL"
echo "Current AWS User: $CURRENT_USER"
echo "Note: EKS UI access has been configured for the current AWS user"

echo
echo "📊 Quick Status Check:"
echo "====================="

# Show node status
echo "EKS Nodes:"
kubectl get nodes

echo
echo "Namespace Overview:"
kubectl get pods --all-namespaces | grep -E "(jenkins|argocd|monitoring|django-app)"

echo
echo "HPA Status:"
kubectl get hpa --all-namespaces

echo
echo "🎉 Deployment Completed Successfully!"
echo "===================================="
echo
echo "Your microservice infrastructure is now ready!"
echo
echo "Next steps:"
echo "1. Run the validation script: ./validate-final-project.sh"
echo "2. Access the services using the port-forward commands above"
echo "3. Configure CI/CD pipelines in Jenkins"
echo "4. Set up GitOps workflows in Argo CD"
echo "5. Create custom dashboards in Grafana"
echo
echo "For troubleshooting, check logs with:"
echo "kubectl logs -f deployment/<service-name> -n <namespace>"
echo
print_success "All systems operational! 🚀"
