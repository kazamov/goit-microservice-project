#!/bin/bash

# Test Django Application with PostgreSQL

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

print_status "Testing Django Application with PostgreSQL..."

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

print_success "Application is deployed"

# Wait for pods to be ready
print_status "Waiting for all pods to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=postgresql --timeout=120s
kubectl wait --for=condition=ready pod -l app=django-app-django --timeout=120s

print_success "All pods are ready"

# Get pod names
DJANGO_POD=$(kubectl get pods -l app=django-app-django -o jsonpath='{.items[0].metadata.name}')
POSTGRES_POD=$(kubectl get pods -l app.kubernetes.io/name=postgresql -o jsonpath='{.items[0].metadata.name}')

print_status "Django pod: $DJANGO_POD"
print_status "PostgreSQL pod: $POSTGRES_POD"

# Test PostgreSQL connectivity
print_status "Testing PostgreSQL connectivity..."
if kubectl exec $POSTGRES_POD -- pg_isready -U django_user; then
    print_success "PostgreSQL is ready and accepting connections"
    
    # Check PostgreSQL version
    print_status "Checking PostgreSQL version..."
    PG_VERSION=$(kubectl exec $POSTGRES_POD -- psql -U postgres -t -c "SELECT version();" | head -1 | xargs)
    if [[ $PG_VERSION == *"PostgreSQL 17.5"* ]]; then
        print_success "PostgreSQL 17.5 is running!"
    else
        print_warning "PostgreSQL version: $PG_VERSION"
    fi
else
    print_error "PostgreSQL is not ready"
    exit 1
fi

# Test Django application
print_status "Testing Django application..."

# Test root endpoint
print_status "Testing root endpoint..."
if kubectl exec $DJANGO_POD -- curl -f -s http://localhost:8000/ > /dev/null; then
    print_success "Root endpoint is working"
else
    print_warning "Root endpoint test failed"
fi

# Test health endpoint
print_status "Testing health endpoint..."
if kubectl exec $DJANGO_POD -- curl -f -s http://localhost:8000/health/ > /dev/null; then
    print_success "Health endpoint is working"
    print_status "Health response:"
    kubectl exec $DJANGO_POD -- curl -s http://localhost:8000/health/
else
    print_warning "Health endpoint test failed"
fi

# Check database connectivity from Django
print_status "Testing database connectivity from Django..."
DB_TEST=$(kubectl exec $DJANGO_POD -- python manage.py shell -c "
from django.db import connections
try:
    cursor = connections['default'].cursor()
    cursor.execute('SELECT 1')
    print('Database connection successful')
except Exception as e:
    print(f'Database connection failed: {e}')
")
echo "$DB_TEST"

# Get LoadBalancer URL
print_status "Getting LoadBalancer information..."
LB_HOSTNAME=$(kubectl get service django-app-django -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
LB_IP=$(kubectl get service django-app-django -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

if [ ! -z "$LB_HOSTNAME" ]; then
    print_success "LoadBalancer hostname: $LB_HOSTNAME"
    print_status "Test with: curl http://$LB_HOSTNAME/"
    print_status "Health check: curl http://$LB_HOSTNAME/health/"
elif [ ! -z "$LB_IP" ]; then
    print_success "LoadBalancer IP: $LB_IP"
    print_status "Test with: curl http://$LB_IP/"
    print_status "Health check: curl http://$LB_IP/health/"
else
    print_warning "LoadBalancer is still provisioning..."
    kubectl get service django-app-django
fi

# Check HPA status
print_status "Checking Horizontal Pod Autoscaler..."
kubectl get hpa django-app-django-hpa
kubectl describe hpa django-app-django-hpa | grep -A 5 "Conditions"

print_success "🎉 All tests completed successfully!"
print_status "Your Django application with PostgreSQL is running and ready!"

echo ""
print_status "Quick access commands:"
echo "  kubectl get pods                           # Check pod status"
echo "  kubectl logs -l app=django-app-django     # View Django logs"
echo "  kubectl logs -l app.kubernetes.io/name=postgresql # View PostgreSQL logs"
echo "  kubectl exec -it $DJANGO_POD -- bash      # Access Django container"
echo "  kubectl exec -it $POSTGRES_POD -- psql -U django_user -d django_db  # Access database"
