#!/bin/bash

# Verify PostgreSQL Version

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

print_status "Checking PostgreSQL Version..."

# Check if kubectl is configured
if ! kubectl cluster-info &> /dev/null; then
    print_error "kubectl is not configured or cluster is not accessible"
    exit 1
fi

# Check if application is deployed
if ! helm list | grep -q "django-app"; then
    print_error "Django application is not deployed. Run ./deploy-app.sh first."
    exit 1
fi

# Get PostgreSQL pod
POSTGRES_POD=$(kubectl get pods -l app.kubernetes.io/name=postgresql -o jsonpath='{.items[0].metadata.name}')

if [ -z "$POSTGRES_POD" ]; then
    print_error "PostgreSQL pod not found"
    exit 1
fi

print_status "PostgreSQL pod: $POSTGRES_POD"

# Check PostgreSQL version
print_status "Checking PostgreSQL version..."
PG_VERSION=$(kubectl exec $POSTGRES_POD -- psql -U postgres -t -c "SELECT version();" | head -1 | xargs)

if [[ $PG_VERSION == *"PostgreSQL 17.5"* ]]; then
    print_success "PostgreSQL 17.5 is running!"
    echo "Full version: $PG_VERSION"
else
    print_warning "PostgreSQL version might be different than expected"
    echo "Current version: $PG_VERSION"
fi

# Check PostgreSQL configuration
print_status "Checking PostgreSQL configuration..."
kubectl exec $POSTGRES_POD -- psql -U postgres -c "SHOW server_version;" || true
kubectl exec $POSTGRES_POD -- psql -U postgres -c "SHOW server_version_num;" || true

# Test connection with Django user
print_status "Testing Django user connection..."
kubectl exec $POSTGRES_POD -- psql -U django_user -d django_db -c "SELECT current_user, current_database(), version();" || print_warning "Django user connection test failed"

print_success "PostgreSQL version check completed!"
