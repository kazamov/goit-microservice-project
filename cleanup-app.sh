#!/bin/bash

# Cleanup Django Application from Kubernetes

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
CLUSTER_NAME="eks-cluster-demo"

print_status "Cleaning up Django application..."

# Configure kubectl for EKS
print_status "Configuring kubectl for EKS..."
aws eks update-kubeconfig --region $AWS_REGION --name $CLUSTER_NAME

# Uninstall Helm release
print_status "Uninstalling Helm release..."
if helm list | grep -q "django-app"; then
    helm uninstall django-app
    print_success "Helm release uninstalled"
else
    print_warning "No Helm release found to uninstall"
fi

# Clean up any remaining PVCs (PostgreSQL data)
print_status "Cleaning up persistent volumes..."
kubectl delete pvc -l app.kubernetes.io/instance=django-app || true

# Verify cleanup
print_status "Verifying cleanup..."
kubectl get deployments | grep django || print_success "No Django deployments found"
kubectl get services | grep django || print_success "No Django services found"
kubectl get services | grep postgresql || print_success "No PostgreSQL services found"
kubectl get hpa | grep django || print_success "No Django HPA found"
kubectl get pvc | grep django || print_success "No Django PVCs found"

print_success "🎉 Cleanup completed successfully!"
