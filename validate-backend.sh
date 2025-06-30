#!/bin/bash

# Validate Backend Infrastructure Script

set -e
set -u
set -o pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}🔍 $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if terraform is installed
if ! command -v terraform &> /dev/null; then
    print_error "Terraform is not installed. Please install Terraform first."
    exit 1
fi

print_status "Validating Backend Infrastructure Configuration..."

# Check if we're in the right directory
if [ ! -f "deploy-backend.sh" ]; then
    print_error "Please run this script from the project root directory"
    exit 1
fi

cd infra-backend

print_status "Checking Terraform configuration files..."

# Check required files
required_files=("main.tf" "variables.tf" "outputs.tf")
for file in "${required_files[@]}"; do
    if [ ! -f "$file" ]; then
        print_error "$file not found"
        exit 1
    fi
    print_success "$file exists"
done

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

print_status "Formatting check..."
if ! terraform fmt -check; then
    echo "Terraform files need formatting. Running terraform fmt..."
    terraform fmt
    print_success "Terraform files formatted"
else
    print_success "Terraform files are properly formatted"
fi

print_status "Planning deployment (dry run)..."
if ! terraform plan -out=validation-plan; then
    print_error "Terraform plan failed"
    exit 1
fi

# Clean up
rm -f validation-plan

print_success "Backend infrastructure configuration is valid!"
print_status "You can now run ./deploy-backend.sh to deploy the infrastructure"
