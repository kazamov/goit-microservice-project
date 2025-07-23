#!/bin/bash

# Cleanup Script for Final Project
# This script safely removes all infrastructure created by the project

set -e

echo "🧹 GoIT Microservice Project - Cleanup"
echo "======================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Get project root directory
PROJECT_ROOT="/Users/zakir/Git/goit-microservice-project"
cd "$PROJECT_ROOT"

echo
print_warning "This will DELETE ALL infrastructure created by this project!"
print_warning "This includes: VPC, EKS, RDS, ECR, S3, DynamoDB, and all applications"
echo
read -p "Are you sure you want to continue? (type 'DELETE' to confirm): " confirmation

if [ "$confirmation" != "DELETE" ]; then
    echo "Cleanup cancelled."
    exit 0
fi

echo
print_step "1" "Cleaning Up Kubernetes Applications"
echo "--------------------------------------------------"

# Update kubeconfig if possible
if aws eks describe-cluster --name eks-cluster-demo &> /dev/null; then
    aws eks update-kubeconfig --region $(aws configure get region || echo "eu-central-1") --name eks-cluster-demo || true
    
    # Delete Django application
    if helm list -n default | grep django-app &> /dev/null; then
        helm uninstall django-app -n default
        print_success "Django application removed"
    fi
    
    # Delete PVCs to avoid stuck volumes
    kubectl delete pvc --all -n jenkins --ignore-not-found=true
    kubectl delete pvc --all -n argocd --ignore-not-found=true
    kubectl delete pvc --all -n monitoring --ignore-not-found=true
    print_success "Persistent Volume Claims cleaned up"
    
    # Wait a moment for cleanup
    sleep 10
fi

echo
print_step "2" "Destroying Main Infrastructure"
echo "----------------------------------------------"

cd main-infra

# Destroy main infrastructure
if [ -f "terraform.tfstate" ] || [ -f ".terraform/terraform.tfstate" ]; then
    echo "Destroying main infrastructure..."
    terraform destroy -auto-approve
    print_success "Main infrastructure destroyed"
else
    print_warning "No main infrastructure state found"
fi

echo
print_step "3" "Cleaning ECR Images"
echo "----------------------------------"

# Clean up ECR repository images
AWS_ACCOUNT=$(aws sts get-caller-identity --query Account --output text 2>/dev/null || echo "")
if [ ! -z "$AWS_ACCOUNT" ]; then
    if aws ecr describe-repositories --repository-names django_app &> /dev/null; then
        # Delete all images in the repository
        aws ecr list-images --repository-name django_app --query 'imageIds[*]' --output json | \
        jq '.[] | select(.imageTag != null) | {imageDigest: .imageDigest}' | \
        jq -s '.' | \
        aws ecr batch-delete-image --repository-name django_app --image-ids file:///dev/stdin &> /dev/null || true
        print_success "ECR images cleaned up"
    fi
fi

echo
print_step "4" "Destroying Backend Infrastructure"
echo "------------------------------------------------"

cd ../infra-backend

# Destroy backend infrastructure (S3 and DynamoDB)
if [ -f "terraform.tfstate" ]; then
    echo "Destroying backend infrastructure..."
    
    # First, we need to empty the S3 bucket
    if [ ! -z "$AWS_ACCOUNT" ]; then
        BUCKET_NAME="terraform-state-bucket-$AWS_ACCOUNT"
        if aws s3 ls "s3://$BUCKET_NAME" &> /dev/null; then
            aws s3 rm "s3://$BUCKET_NAME" --recursive
            print_success "S3 bucket emptied"
        fi
    fi
    
    terraform destroy -auto-approve
    print_success "Backend infrastructure destroyed"
else
    print_warning "No backend infrastructure state found"
fi

echo
print_step "5" "Cleaning Local Files"
echo "-----------------------------------"

# Clean up Terraform files
find "$PROJECT_ROOT" -name "*.tfplan" -delete
find "$PROJECT_ROOT" -name "terraform.tfstate*" -delete
find "$PROJECT_ROOT" -name ".terraform.lock.hcl" -delete
find "$PROJECT_ROOT" -type d -name ".terraform" -exec rm -rf {} + 2>/dev/null || true

# Clean up Helm backup files
find "$PROJECT_ROOT" -name "values.yaml.bak" -delete

print_success "Local cleanup completed"

echo
print_step "6" "Verification"
echo "---------------------------"

# Verify cleanup
echo "Checking for remaining AWS resources..."

# Check VPC
VPC_COUNT=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=main-vpc" --query 'length(Vpcs)' --output text 2>/dev/null || echo "0")
if [ "$VPC_COUNT" = "0" ]; then
    print_success "VPC removed"
else
    print_warning "$VPC_COUNT VPC(s) still exist"
fi

# Check EKS
if aws eks describe-cluster --name eks-cluster-demo &> /dev/null; then
    print_warning "EKS cluster still exists (may take a few minutes to fully delete)"
else
    print_success "EKS cluster removed"
fi

# Check RDS
if aws rds describe-db-instances --db-instance-identifier myapp-db &> /dev/null; then
    print_warning "RDS instance still exists (may take a few minutes to fully delete)"
else
    print_success "RDS instance removed"
fi

# Check ECR
if aws ecr describe-repositories --repository-names django_app &> /dev/null; then
    print_warning "ECR repository still exists"
else
    print_success "ECR repository removed"
fi

# Check S3
if [ ! -z "$AWS_ACCOUNT" ]; then
    BUCKET_NAME="terraform-state-bucket-$AWS_ACCOUNT"
    if aws s3 ls "s3://$BUCKET_NAME" &> /dev/null; then
        print_warning "S3 bucket still exists"
    else
        print_success "S3 bucket removed"
    fi
fi

# Check DynamoDB
if aws dynamodb describe-table --table-name terraform-locks &> /dev/null; then
    print_warning "DynamoDB table still exists"
else
    print_success "DynamoDB table removed"
fi

echo
echo "🧹 Cleanup Summary"
echo "=================="
echo
echo "Completed cleanup tasks:"
echo "✅ Kubernetes applications removed"
echo "✅ Main infrastructure destroyed"
echo "✅ ECR images cleaned"
echo "✅ Backend infrastructure destroyed"
echo "✅ Local files cleaned"
echo
print_warning "Note: Some AWS resources may take a few minutes to fully delete"
print_warning "You can verify complete cleanup in the AWS Console"
echo
echo "If you need to redeploy, run: ./deploy-final-project.sh"
echo
print_success "Cleanup completed! 🧹"
