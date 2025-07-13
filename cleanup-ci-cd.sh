#!/bin/bash

# Cleanup CI/CD Infrastructure
# This script removes all CI/CD infrastructure components

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Confirm cleanup
confirm_cleanup() {
    echo -e "${RED}WARNING: This will destroy all CI/CD infrastructure!${NC}"
    echo "This includes:"
    echo "  - Jenkins"
    echo "  - Argo CD"
    echo "  - EKS cluster"
    echo "  - VPC"
    echo "  - ECR repository"
    echo "  - All deployed applications"
    echo ""
    
    read -p "Are you sure you want to continue? (yes/no): " -r
    if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        print_status "Cleanup cancelled."
        exit 0
    fi
}

# Remove Django application from Argo CD
cleanup_django_app() {
    print_status "Removing Django application..."
    
    if kubectl get application django-app -n argocd > /dev/null 2>&1; then
        kubectl delete application django-app -n argocd || true
        print_status "Django application removed from Argo CD"
    fi
    
    # Wait for cleanup
    print_status "Waiting for application cleanup..."
    sleep 30
    
    # Force delete namespace if stuck
    if kubectl get namespace django-app > /dev/null 2>&1; then
        kubectl delete namespace django-app --force --grace-period=0 || true
    fi
}

# Cleanup Helm releases
cleanup_helm_releases() {
    print_status "Cleaning up Helm releases..."
    
    # Remove Jenkins
    if helm list -n jenkins | grep -q jenkins; then
        helm uninstall jenkins -n jenkins || true
        print_status "Jenkins Helm release removed"
    fi
    
    # Remove Argo CD
    if helm list -n argocd | grep -q argocd; then
        helm uninstall argocd -n argocd || true
        print_status "Argo CD Helm release removed"
    fi
    
    # Wait for cleanup
    sleep 30
}

# Cleanup namespaces
cleanup_namespaces() {
    print_status "Cleaning up namespaces..."
    
    for ns in jenkins argocd django-app; do
        if kubectl get namespace $ns > /dev/null 2>&1; then
            kubectl delete namespace $ns --force --grace-period=0 || true
            print_status "Namespace $ns deleted"
        fi
    done
}

# Cleanup persistent volumes
cleanup_storage() {
    print_status "Cleaning up persistent storage..."
    
    # Delete all PVCs
    kubectl get pvc --all-namespaces -o jsonpath='{range .items[*]}{.metadata.namespace}{" "}{.metadata.name}{"\n"}{end}' | \
    while read namespace pvc; do
        if [[ -n "$namespace" && -n "$pvc" ]]; then
            kubectl delete pvc $pvc -n $namespace --force --grace-period=0 || true
        fi
    done
    
    # Delete PVs
    kubectl get pv -o name | xargs -I {} kubectl delete {} --force --grace-period=0 || true
}

# Destroy Terraform infrastructure
destroy_terraform() {
    print_status "Destroying Terraform infrastructure..."
    
    # Destroy main infrastructure
    cd main-infra
    if [ -f "terraform.tfstate" ] || [ -d ".terraform" ]; then
        terraform destroy -auto-approve || true
        print_status "Main infrastructure destroyed"
    fi
    cd ..
    
    # Destroy backend infrastructure
    cd infra-backend
    if [ -f "terraform.tfstate" ] || [ -d ".terraform" ]; then
        print_warning "Backend infrastructure contains Terraform state. Skipping destruction."
        print_warning "To destroy backend, run: cd infra-backend && terraform destroy"
    fi
    cd ..
}

# Clean up ECR images (optional)
cleanup_ecr_images() {
    print_status "Cleaning up ECR images..."
    
    if aws ecr describe-repositories --repository-names django_app --region eu-central-1 > /dev/null 2>&1; then
        # Delete all images
        aws ecr batch-delete-image \
            --repository-name django_app \
            --region eu-central-1 \
            --image-ids "$(aws ecr list-images --repository-name django_app --region eu-central-1 --query 'imageIds[*]' --output json)" \
            > /dev/null 2>&1 || true
        
        print_status "ECR images cleaned up"
    fi
}

# Update kubeconfig
cleanup_kubeconfig() {
    print_status "Cleaning up kubectl configuration..."
    
    # Remove EKS cluster from kubeconfig
    kubectl config get-contexts -o name | grep -E "eks-cluster|arn:aws:eks" | \
    while read context; do
        kubectl config delete-context "$context" || true
    done
    
    kubectl config get-clusters | grep -E "eks-cluster|arn:aws:eks" | \
    while read cluster; do
        kubectl config delete-cluster "$cluster" || true
    done
    
    kubectl config get-users | grep -E "eks-cluster|arn:aws:eks" | \
    while read user; do
        kubectl config delete-user "$user" || true
    done
}

# Main cleanup function
main() {
    print_status "Starting CI/CD infrastructure cleanup..."
    
    confirm_cleanup
    
    # Check if kubectl is configured
    if ! kubectl cluster-info > /dev/null 2>&1; then
        print_warning "kubectl is not configured or cluster is not accessible"
        print_status "Proceeding with Terraform cleanup only..."
        destroy_terraform
        return 0
    fi
    
    # Cleanup in order
    cleanup_django_app
    cleanup_helm_releases
    cleanup_namespaces
    cleanup_storage
    cleanup_ecr_images
    
    # Wait a bit before destroying infrastructure
    print_status "Waiting before destroying infrastructure..."
    sleep 60
    
    destroy_terraform
    cleanup_kubeconfig
    
    print_status "CI/CD infrastructure cleanup completed!"
    print_warning "Note: Backend infrastructure (S3 + DynamoDB) was preserved."
    print_warning "To clean up backend: cd infra-backend && terraform destroy"
}

# Run main function
main "$@"
