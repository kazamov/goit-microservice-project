#!/bin/bash

# Deploy Backend Infrastructure Script

set -e  # Exit on any error
set -u  # Exit on undefined variables
set -o pipefail  # Exit on pipe failures

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

# Check if terraform is installed
if ! command -v terraform &> /dev/null; then
    print_error "Terraform is not installed. Please install Terraform first."
    exit 1
fi

print_status "Deploying Backend Infrastructure..."

# Check if we're in the right directory
if [ ! -f "deploy-backend.sh" ]; then
    print_error "Please run this script from the project root directory"
    exit 1
fi

cd infra-backend

# Check if main.tf exists
if [ ! -f "main.tf" ]; then
    print_error "main.tf not found in infra-backend directory"
    exit 1
fi

print_status "Initializing Terraform..."
if ! terraform init; then
    print_error "Terraform initialization failed"
    exit 1
fi

print_status "Validating Terraform configuration..."
if ! terraform validate; then
    print_error "Terraform validation failed"
    exit 1
fi

print_status "Planning deployment..."
if ! terraform plan -out=tfplan; then
    print_error "Terraform plan failed"
    exit 1
fi

print_warning "About to apply Terraform configuration. This will create AWS resources."
read -p "Do you want to continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_warning "Deployment cancelled by user"
    rm -f tfplan
    exit 0
fi

print_status "Applying configuration..."
if ! terraform apply tfplan; then
    print_error "Terraform apply failed"
    rm -f tfplan
    exit 1
fi

rm -f tfplan

print_success "Backend infrastructure deployed successfully!"
echo ""
print_status "Backend Configuration:"
terraform output backend_config

echo ""
print_success "Next steps:"
echo "   1. cd ../main-infra"
echo "   2. terraform init"
echo "   3. terraform apply"
