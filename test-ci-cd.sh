#!/bin/bash

# Test CI/CD Pipeline
# This script tests the entire CI/CD pipeline

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

print_header() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

# Test Jenkins accessibility
test_jenkins() {
    print_header "Testing Jenkins"
    
    JENKINS_URL="http://$(kubectl get svc -n jenkins jenkins -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'):80"
    
    if curl -s -f "$JENKINS_URL/login" > /dev/null 2>&1; then
        print_status "✓ Jenkins is accessible at: $JENKINS_URL"
        
        # Check if our job exists
        if curl -s -u "admin:admin123" "$JENKINS_URL/job/django-app-pipeline/api/json" > /dev/null 2>&1; then
            print_status "✓ Django pipeline job exists"
        else
            print_warning "⚠ Django pipeline job not found"
        fi
    else
        print_error "✗ Jenkins is not accessible"
        return 1
    fi
}

# Test Argo CD accessibility
test_argocd() {
    print_header "Testing Argo CD"
    
    ARGOCD_URL="https://$(kubectl get svc -n argocd argocd-server -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'):443"
    
    if curl -s -k -f "$ARGOCD_URL" > /dev/null 2>&1; then
        print_status "✓ Argo CD is accessible at: $ARGOCD_URL"
        
        # Check if our application exists
        if kubectl get application django-app -n argocd > /dev/null 2>&1; then
            print_status "✓ Django application is configured in Argo CD"
            
            # Check sync status
            SYNC_STATUS=$(kubectl get application django-app -n argocd -o jsonpath='{.status.sync.status}')
            HEALTH_STATUS=$(kubectl get application django-app -n argocd -o jsonpath='{.status.health.status}')
            
            print_status "  Sync Status: $SYNC_STATUS"
            print_status "  Health Status: $HEALTH_STATUS"
        else
            print_warning "⚠ Django application not found in Argo CD"
        fi
    else
        print_error "✗ Argo CD is not accessible"
        return 1
    fi
}

# Test ECR repository
test_ecr() {
    print_header "Testing ECR Repository"
    
    if aws ecr describe-repositories --repository-names django_app --region eu-central-1 > /dev/null 2>&1; then
        print_status "✓ ECR repository 'django_app' exists"
        
        # Check if there are any images
        IMAGE_COUNT=$(aws ecr describe-images --repository-name django_app --region eu-central-1 --query 'length(imageDetails)' --output text 2>/dev/null || echo "0")
        print_status "  Images in repository: $IMAGE_COUNT"
    else
        print_error "✗ ECR repository 'django_app' not found"
        return 1
    fi
}

# Test EKS cluster
test_eks() {
    print_header "Testing EKS Cluster"
    
    if kubectl cluster-info > /dev/null 2>&1; then
        print_status "✓ kubectl can connect to EKS cluster"
        
        # Check nodes
        NODE_COUNT=$(kubectl get nodes --no-headers | wc -l)
        print_status "  Active nodes: $NODE_COUNT"
        
        # Check namespaces
        if kubectl get namespace jenkins > /dev/null 2>&1; then
            print_status "✓ Jenkins namespace exists"
        fi
        
        if kubectl get namespace argocd > /dev/null 2>&1; then
            print_status "✓ ArgoCD namespace exists"
        fi
        
        if kubectl get namespace django-app > /dev/null 2>&1; then
            print_status "✓ Django-app namespace exists"
        else
            print_warning "⚠ Django-app namespace not found (will be created on first deployment)"
        fi
    else
        print_error "✗ Cannot connect to EKS cluster"
        return 1
    fi
}

# Test Django application (if deployed)
test_django_app() {
    print_header "Testing Django Application"
    
    if kubectl get namespace django-app > /dev/null 2>&1; then
        if kubectl get deployment django-app -n django-app > /dev/null 2>&1; then
            print_status "✓ Django deployment exists"
            
            # Check deployment status
            READY_REPLICAS=$(kubectl get deployment django-app -n django-app -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
            DESIRED_REPLICAS=$(kubectl get deployment django-app -n django-app -o jsonpath='{.spec.replicas}')
            
            print_status "  Ready replicas: $READY_REPLICAS/$DESIRED_REPLICAS"
            
            # Check service
            if kubectl get service django-app -n django-app > /dev/null 2>&1; then
                DJANGO_URL="http://$(kubectl get svc django-app -n django-app -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'):8000"
                print_status "✓ Django service exists"
                print_status "  Django URL: $DJANGO_URL"
                
                # Test if Django is responding
                if curl -s -f "$DJANGO_URL" > /dev/null 2>&1; then
                    print_status "✓ Django application is responding"
                else
                    print_warning "⚠ Django application is not responding yet"
                fi
            fi
            
            # Check HPA
            if kubectl get hpa django-app -n django-app > /dev/null 2>&1; then
                print_status "✓ HPA is configured"
            fi
        else
            print_warning "⚠ Django deployment not found (not deployed yet)"
        fi
    else
        print_warning "⚠ Django namespace not found (not deployed yet)"
    fi
}

# Trigger test build
trigger_test_build() {
    print_header "Triggering Test Build"
    
    JENKINS_URL="http://$(kubectl get svc -n jenkins jenkins -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'):80"
    
    print_status "Triggering Jenkins build..."
    if curl -X POST -u "admin:admin123" "$JENKINS_URL/job/django-app-pipeline/build" > /dev/null 2>&1; then
        print_status "✓ Build triggered successfully"
        print_status "  Check build progress: $JENKINS_URL/job/django-app-pipeline/"
    else
        print_error "✗ Failed to trigger build"
    fi
}

# Main execution
main() {
    print_header "CI/CD Pipeline Test Suite"
    
    echo ""
    test_eks
    echo ""
    test_ecr
    echo ""
    test_jenkins
    echo ""
    test_argocd
    echo ""
    test_django_app
    
    echo ""
    print_header "Test Summary"
    
    if kubectl get job django-app-pipeline -n jenkins > /dev/null 2>&1; then
        print_status "Pipeline has been executed"
    else
        print_warning "Pipeline has not been executed yet"
        
        read -p "Do you want to trigger a test build? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo ""
            trigger_test_build
        fi
    fi
    
    echo ""
    print_status "All tests completed!"
    print_status "Monitor the pipeline progress in Jenkins and check Argo CD for automatic synchronization."
}

# Run main function
main "$@"
