#!/bin/bash

# Deploy CI/CD Pipeline with Jenkins + Argo CD
# This script deploys the full CI/CD infrastructure including Jenkins and Argo CD

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if required tools are installed
check_dependencies() {
    print_status "Checking dependencies..."
    
    for cmd in terraform kubectl helm aws; do
        if ! command -v $cmd &> /dev/null; then
            print_error "$cmd is not installed. Please install it first."
            exit 1
        fi
    done
    
    print_status "All dependencies are available."
}

# Deploy backend infrastructure
deploy_backend() {
    print_status "Deploying backend infrastructure (S3 + DynamoDB)..."
    
    cd infra-backend
    terraform init
    terraform apply -auto-approve
    cd ..
    
    print_status "Backend infrastructure deployed successfully."
}

# Deploy main infrastructure with Jenkins and Argo CD
deploy_main_infrastructure() {
    print_status "Deploying main infrastructure (VPC + ECR + EKS + Jenkins + ArgoCD)..."
    
    cd main-infra
    terraform init
    terraform apply -auto-approve
    cd ..
    
    print_status "Main infrastructure deployed successfully."
}

# Configure kubectl context
configure_kubectl() {
    print_status "Configuring kubectl for EKS cluster..."
    
    CLUSTER_NAME=$(cd main-infra && terraform output -raw cluster_name)
    aws eks update-kubeconfig --region eu-central-1 --name $CLUSTER_NAME
    
    print_status "kubectl configured successfully."
}

# Get access information
get_access_info() {
    print_status "Getting access information..."
    
    cd main-infra
    
    echo ""
    print_status "=== JENKINS ACCESS ==="
    echo "Jenkins URL: http://$(kubectl get svc -n jenkins jenkins -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'):80"
    echo "Username: admin"
    echo "Password: admin123"
    
    echo ""
    print_status "=== ARGO CD ACCESS ==="
    echo "ArgoCD URL: https://$(kubectl get svc -n argocd argocd-server -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'):443"
    echo "Username: admin"
    echo "Password: $(kubectl get secret -n argocd argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d)"
    
    echo ""
    print_status "=== ECR REPOSITORY ==="
    terraform output ecr_repository_url
    
    cd ..
}

# Wait for services to be ready
wait_for_services() {
    print_status "Waiting for services to be ready..."
    
    # Wait for Jenkins
    print_status "Waiting for Jenkins to be ready..."
    kubectl wait --for=condition=ready pod -l app.kubernetes.io/component=jenkins-controller -n jenkins --timeout=600s
    
    # Wait for ArgoCD
    print_status "Waiting for ArgoCD to be ready..."
    kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=600s
    
    print_status "All services are ready."
}

# Main execution
main() {
    print_status "Starting CI/CD deployment..."
    
    check_dependencies
    deploy_backend
    deploy_main_infrastructure
    configure_kubectl
    wait_for_services
    get_access_info
    
    echo ""
    print_status "=== NEXT STEPS ==="
    echo "1. Access Jenkins and configure the GitHub token credential"
    echo "2. Create a new Pipeline job pointing to your Django app Jenkinsfile"
    echo "3. Run the Jenkins pipeline to build and deploy your Django app"
    echo "4. Check ArgoCD to see the automatic synchronization"
    echo ""
    print_status "CI/CD pipeline deployment completed successfully!"
}

# Run main function
main "$@"
