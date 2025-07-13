#!/bin/bash

# Check PostgreSQL Chart Information

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

print_status "Checking PostgreSQL Chart Information..."

# Check Chart.yaml
if [ -f "Chart.yaml" ]; then
    print_status "Current Chart.yaml dependency:"
    grep -A 4 "dependencies:" Chart.yaml
    echo ""
    
    CHART_VERSION=$(grep "version:" Chart.yaml | grep -v "appVersion" | head -1 | awk '{print $2}' | tr -d '"')
    print_status "PostgreSQL chart version: $CHART_VERSION"
else
    print_error "Chart.yaml not found. Please run from the charts/django-app directory."
    exit 1
fi

# Check what PostgreSQL version this chart supports
print_status "Checking PostgreSQL version for this chart..."
if command -v helm &> /dev/null; then
    # Make sure repo is updated
    helm repo add bitnami https://charts.bitnami.com/bitnami 2>/dev/null || true
    helm repo update > /dev/null 2>&1
    
    # Show chart information
    POSTGRESQL_INFO=$(helm search repo bitnami/postgresql --version="$CHART_VERSION" 2>/dev/null)
    if [ ! -z "$POSTGRESQL_INFO" ]; then
        echo "$POSTGRESQL_INFO"
        
        APP_VERSION=$(echo "$POSTGRESQL_INFO" | tail -n +2 | awk '{print $3}')
        if [[ $APP_VERSION == *"17.5"* ]]; then
            print_success "✅ Chart version $CHART_VERSION supports PostgreSQL 17.5!"
        else
            print_warning "Chart version $CHART_VERSION supports PostgreSQL $APP_VERSION"
        fi
    else
        print_warning "Could not find chart information for version $CHART_VERSION"
    fi
else
    print_warning "Helm not found. Cannot verify chart information."
fi

# Check values.yaml
if [ -f "values.yaml" ]; then
    print_status "PostgreSQL configuration in values.yaml:"
    grep -A 15 "postgresql:" values.yaml | head -20
else
    print_warning "values.yaml not found"
fi

print_success "PostgreSQL chart check completed!"
