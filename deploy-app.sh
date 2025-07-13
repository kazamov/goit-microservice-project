#!/bin/bash

# Deploy Django Application to ECR and Kubernetes

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}🚀 $1${NC}"
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

# Configuration
AWS_REGION="eu-central-1"
AWS_ACCOUNT_ID="127214174194"
ECR_REPOSITORY="django_app"
IMAGE_TAG="latest"
CLUSTER_NAME="eks-cluster-demo"

# Check required tools
print_status "Checking required tools..."
for tool in aws docker kubectl helm; do
    if ! command -v $tool &> /dev/null; then
        print_error "$tool is not installed. Please install $tool first."
        exit 1
    fi
done
print_success "All required tools are available"

# Get ECR login token and login to ECR
print_status "Logging into ECR..."
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com
print_success "Successfully logged into ECR"

# Build Django Docker image
print_status "Building Django Docker image..."
cd django_app
docker build -t $ECR_REPOSITORY:$IMAGE_TAG . --platform linux/amd64
print_success "Django Docker image built successfully"

# Tag image for ECR
print_status "Tagging image for ECR..."
docker tag $ECR_REPOSITORY:$IMAGE_TAG $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY:$IMAGE_TAG
print_success "Image tagged for ECR"

# Push image to ECR
print_status "Pushing image to ECR..."
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY:$IMAGE_TAG
print_success "Image pushed to ECR successfully"

cd ..

# Configure kubectl for EKS
print_status "Configuring kubectl for EKS..."
aws eks update-kubeconfig --region $AWS_REGION --name $CLUSTER_NAME
print_success "kubectl configured for EKS cluster"

# Check cluster status
print_status "Checking cluster status..."
kubectl cluster-info
kubectl get nodes

# Deploy with Helm
print_status "Deploying Django application with Helm..."
cd charts/django-app

# Add Bitnami repository
print_status "Adding Bitnami Helm repository..."
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# Clean and download dependencies
print_status "Cleaning and downloading chart dependencies..."
rm -rf charts/
helm dependency update

# Check if release already exists
if helm list | grep -q "django-app"; then
    print_status "Upgrading existing Helm release..."
    helm upgrade django-app . --wait --timeout=600s
else
    print_status "Installing new Helm release..."
    helm install django-app . --wait --timeout=600s
fi

print_success "Django application deployed successfully!"

# Wait for PostgreSQL to be ready
print_status "Waiting for PostgreSQL to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=postgresql --timeout=300s

# Wait for Django pods to be ready
print_status "Waiting for Django pods to be ready..."
kubectl wait --for=condition=ready pod -l app=django-app-django --timeout=300s

# Show deployment status
print_status "Checking deployment status..."
kubectl get deployments
kubectl get services
kubectl get hpa
kubectl get pods
kubectl get pvc

# Test application connectivity
print_status "Testing application connectivity..."
DJANGO_POD=$(kubectl get pods -l app=django-app-django -o jsonpath='{.items[0].metadata.name}')
if [ ! -z "$DJANGO_POD" ]; then
    print_status "Testing health endpoint..."
    kubectl exec $DJANGO_POD -- curl -f http://localhost:8000/health/ || print_warning "Health check failed - this is normal during initial deployment"
fi

# Get LoadBalancer URL
print_status "Getting LoadBalancer URL..."
kubectl get service django-app-django -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
echo ""

print_success "🎉 Deployment completed successfully!"
print_warning "Note: It may take a few minutes for the LoadBalancer to become available."
print_status "Use 'kubectl get service django-app-django' to check the LoadBalancer status."
