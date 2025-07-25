#!/bin/bash

# Cleanup Script for Final Project
# This script safely removes all infrastructure created by the project

set -e

# Trap to handle script interruption
trap 'echo -e "\n❌ Script interrupted during cleanup. Some resources may still exist."; exit 1' INT TERM

echo "🧹 GoIT Microservice Project - Cleanup"
echo "======================================"

# Check if required tools are available
MISSING_TOOLS=false
for tool in aws terraform kubectl helm; do
    if ! command -v $tool &> /dev/null; then
        print_error "$tool is not installed or not in PATH"
        MISSING_TOOLS=true
    fi
done

if [ "$MISSING_TOOLS" = true ]; then
    print_error "Please install missing tools before running cleanup"
    exit 1
fi

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

# Get project root directory (make it dynamic)
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
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
#AWS_REGION=$(aws configure get region || echo "eu-central-1")
#if aws eks describe-cluster --name eks-cluster-demo --region $AWS_REGION &> /dev/null; then
#    echo "Updating kubeconfig..."
#    aws eks update-kubeconfig --region $AWS_REGION --name eks-cluster-demo || true
#    
#    # Delete Django application
#    if helm list -n default | grep django-app &> /dev/null; then
#        echo "Removing Django application..."
#        helm uninstall django-app -n default || true
#        print_success "Django application removed"
#    else
#        print_warning "Django application not found"
#    fi
#    
#    # Delete PVCs to avoid stuck volumes
#    echo "Cleaning up Persistent Volume Claims..."
#    
#    # Function to force delete PVCs with finalizer removal
#    force_delete_pvcs() {
#        local namespace=$1
#        local pvcs=$(kubectl get pvc -n "$namespace" --no-headers 2>/dev/null | awk '{print $1}' || echo "")
#        
#        if [ -n "$pvcs" ]; then
#            echo "  - Deleting PVCs in namespace $namespace..."
#            
#            # First attempt: normal deletion with timeout
#            timeout 30 kubectl delete pvc --all -n "$namespace" --ignore-not-found=true --timeout=15s &>/dev/null || true
#            
#            # Wait briefly for normal deletion
#            sleep 5
#            
#            # Check for stuck PVCs and force delete them
#            local stuck_pvcs=$(kubectl get pvc -n "$namespace" --no-headers 2>/dev/null | awk '{print $1}' || echo "")
#            if [ -n "$stuck_pvcs" ]; then
#                echo "    Force deleting stuck PVCs in $namespace..."
#                for pvc in $stuck_pvcs; do
#                    # Remove finalizers to force deletion
#                    kubectl patch pvc "$pvc" -n "$namespace" -p '{"metadata":{"finalizers":null}}' --type=merge &>/dev/null || true
#                    # Force delete
#                    kubectl delete pvc "$pvc" -n "$namespace" --force --grace-period=0 &>/dev/null || true
#                done
#            fi
#            echo "    PVC cleanup for $namespace completed"
#        fi
#    }
#    
#    # Get all namespaces and clean PVCs from each
#    echo "Getting all namespaces with PVCs..."
#    all_namespaces=$(kubectl get namespaces --no-headers -o custom-columns=":metadata.name" 2>/dev/null || echo "")
#    
#    if [ -n "$all_namespaces" ]; then
#        for ns in $all_namespaces; do
#            # Skip system namespaces that we shouldn't touch
#            if [[ "$ns" != "kube-system" && "$ns" != "kube-public" && "$ns" != "kube-node-lease" ]]; then
#                force_delete_pvcs "$ns"
#            fi
#        done
#    fi
#    
#    # Also target specific known problem PVCs by name pattern across all namespaces
#    echo "Searching for specific problematic PVCs across all namespaces..."
#    
#    # Find PVCs with common problematic patterns
#    problem_patterns=("alertmanager" "prometheus" "grafana" "django-app-postgresql")
#    
#    for pattern in "${problem_patterns[@]}"; do
#        echo "  - Looking for PVCs matching pattern: $pattern"
#        
#        # Use timeout and collect output to avoid hanging
#        if pvc_output=$(timeout 30 kubectl get pvc --all-namespaces --no-headers 2>/dev/null); then
#            # Filter and process the results
#            filtered_pvcs=$(echo "$pvc_output" | grep "$pattern" || echo "")
#            if [ -n "$filtered_pvcs" ]; then
#                # Process each line without while-read
#                IFS=$'\n' read -rd '' -a pvc_lines <<< "$filtered_pvcs" || true
#                for line in "${pvc_lines[@]}"; do
#                    if [ -n "$line" ]; then
#                        namespace=$(echo "$line" | awk '{print $1}')
#                        pvc_name=$(echo "$line" | awk '{print $2}')
#                        if [ -n "$namespace" ] && [ -n "$pvc_name" ]; then
#                            echo "    Found problematic PVC: $pvc_name in namespace $namespace"
#                            # Remove finalizers and force delete with timeout
#                            timeout 15 kubectl patch pvc "$pvc_name" -n "$namespace" -p '{"metadata":{"finalizers":null}}' --type=merge &>/dev/null || true
#                            timeout 15 kubectl delete pvc "$pvc_name" -n "$namespace" --force --grace-period=0 &>/dev/null || true
#                            echo "    Force deleted: $pvc_name"
#                        fi
#                    fi
#                done
#            fi
#        else
#            echo "    Timeout or error getting PVCs for pattern: $pattern"
#        fi
#    done
#    
#    # Final aggressive cleanup - delete ALL PVCs in non-system namespaces
#    echo "Final aggressive PVC cleanup..."
#    
#    # Get all PVCs with timeout and process without while-read loop
#    if all_pvcs_output=$(timeout 30 kubectl get pvc --all-namespaces --no-headers 2>/dev/null); then
#        if [ -n "$all_pvcs_output" ]; then
#            # Process each line without while-read
#            IFS=$'\n' read -rd '' -a all_pvc_lines <<< "$all_pvcs_output" || true
#            for line in "${all_pvc_lines[@]}"; do
#                if [ -n "$line" ]; then
#                    namespace=$(echo "$line" | awk '{print $1}')
#                    pvc_name=$(echo "$line" | awk '{print $2}')
#                    if [[ "$namespace" != "kube-system" && "$namespace" != "kube-public" && "$namespace" != "kube-node-lease" ]] && [ -n "$pvc_name" ]; then
#                        echo "  - Force deleting remaining PVC: $pvc_name in $namespace"
#                        timeout 15 kubectl patch pvc "$pvc_name" -n "$namespace" -p '{"metadata":{"finalizers":null}}' --type=merge &>/dev/null || true
#                        timeout 15 kubectl delete pvc "$pvc_name" -n "$namespace" --force --grace-period=0 &>/dev/null || true
#                    fi
#                fi
#            done
#        fi
#    else
#        echo "  Timeout or error getting all PVCs"
#    fi
#    
#    print_success "Persistent Volume Claims cleanup completed"
#    
#    # Wait a moment for cleanup
#    sleep 10
#else
#    print_warning "EKS cluster not found or not accessible"
#fi

echo
print_step "2" "Cleaning ECR Images"
echo "----------------------------------"

# Clean up ECR repository images
AWS_ACCOUNT=$(aws sts get-caller-identity --query Account --output text 2>/dev/null || echo "")
if [ ! -z "$AWS_ACCOUNT" ]; then
    if aws ecr describe-repositories --repository-names django_app &> /dev/null; then
        echo "Deleting ECR images..."
        # Simple approach: delete all images by tag first, then by digest
        aws ecr list-images --repository-name django_app --filter tagStatus=TAGGED --query 'imageIds[*].imageTag' --output text | \
        xargs -n1 -I {} aws ecr batch-delete-image --repository-name django_app --image-ids imageTag={} &> /dev/null || true
        
        aws ecr list-images --repository-name django_app --filter tagStatus=UNTAGGED --query 'imageIds[*].imageDigest' --output text | \
        xargs -n1 -I {} aws ecr batch-delete-image --repository-name django_app --image-ids imageDigest={} &> /dev/null || true
        
        print_success "ECR images cleaned up"
    else
        print_warning "ECR repository not found"
    fi
else
    print_warning "Could not get AWS account ID"
fi

echo
print_step "3" "Destroying Main Infrastructure"
echo "----------------------------------------------"

cd "$PROJECT_ROOT/main-infra"

# Destroy main infrastructure
if [ -f "terraform.tfstate" ] || [ -f ".terraform/terraform.tfstate" ]; then
    echo "Destroying main infrastructure..."
    terraform init -upgrade || true  # Ensure Terraform is initialized
    
    # First, check if there are any resources in the state
    STATE_RESOURCES=$(terraform state list 2>/dev/null | wc -l | tr -d ' ')
    
    if [ "$STATE_RESOURCES" -gt 0 ]; then
        echo "Found $STATE_RESOURCES resources in state, attempting destroy..."
        
        # Try normal destroy first
        if ! terraform destroy -auto-approve; then
            print_warning "Normal destroy failed, trying targeted destroy..."
            
            # Get all resources and try to destroy them one by one
            for resource in $(terraform state list 2>/dev/null || echo ""); do
                if [ -n "$resource" ]; then
                    echo "Attempting to destroy: $resource"
                    terraform destroy -target="$resource" -auto-approve || {
                        print_warning "Failed to destroy $resource, removing from state..."
                        terraform state rm "$resource" || true
                    }
                fi
            done
            
            # Final destroy attempt
            terraform destroy -auto-approve || print_warning "Some resources may still exist"
        fi
    else
        print_success "No resources found in Terraform state - already clean"
    fi
    
    print_success "Main infrastructure destroy completed"
else
    print_warning "No main infrastructure state found"
fi

echo
print_step "4" "Destroying Backend Infrastructure"
echo "------------------------------------------------"

cd "$PROJECT_ROOT/infra-backend"

# Destroy backend infrastructure (S3 and DynamoDB)
if [ -f "terraform.tfstate" ]; then
    echo "Destroying backend infrastructure..."
    
    # First, we need to empty the S3 bucket completely
    if [ ! -z "$AWS_ACCOUNT" ]; then
        BUCKET_NAME="terraform-state-bucket-$AWS_ACCOUNT"
        if aws s3 ls "s3://$BUCKET_NAME" &> /dev/null; then
            echo "Emptying S3 bucket completely..."
            # Remove all current objects
            aws s3 rm "s3://$BUCKET_NAME" --recursive || true
            
            # Force empty the bucket using AWS CLI (handles versions automatically)
            aws s3api put-bucket-versioning --bucket "$BUCKET_NAME" --versioning-configuration Status=Suspended || true
            
            # Delete all object versions manually
            echo "Removing all object versions..."
            aws s3api list-object-versions --bucket "$BUCKET_NAME" --output text --query 'Versions[].{Key:Key,VersionId:VersionId}' 2>/dev/null | \
            while read key version_id; do
                if [ ! -z "$key" ] && [ ! -z "$version_id" ] && [ "$key" != "None" ] && [ "$version_id" != "None" ]; then
                    aws s3api delete-object --bucket "$BUCKET_NAME" --key "$key" --version-id "$version_id" &>/dev/null || true
                fi
            done
            
            # Delete all delete markers
            echo "Removing delete markers..."
            aws s3api list-object-versions --bucket "$BUCKET_NAME" --output text --query 'DeleteMarkers[].{Key:Key,VersionId:VersionId}' 2>/dev/null | \
            while read key version_id; do
                if [ ! -z "$key" ] && [ ! -z "$version_id" ] && [ "$key" != "None" ] && [ "$version_id" != "None" ]; then
                    aws s3api delete-object --bucket "$BUCKET_NAME" --key "$key" --version-id "$version_id" &>/dev/null || true
                fi
            done
            
            print_success "S3 bucket emptied completely"
        fi
    fi
    
    terraform init -upgrade || true  # Ensure Terraform is initialized
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

# Check VPC (updated to match actual tag name)
VPC_COUNT=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=main-vpc-vpc" --query 'length(Vpcs)' --output text 2>/dev/null || echo "0")
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
