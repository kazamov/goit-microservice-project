#!/bin/bash

# Django App Deployment Helper Script
# This script provides easy access to common deployment operations

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print status
print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
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

# Function to check if kubectl is configured
check_kubectl() {
    if ! kubectl cluster-info &> /dev/null; then
        print_error "kubectl is not configured or cluster is not accessible"
        exit 1
    fi
    print_success "kubectl is configured and cluster is accessible"
}

# Function to show deployment status
show_status() {
    print_info "Django Application Deployment Status"
    echo "=================================="
    
    echo
    echo "📦 Deployments:"
    kubectl get deployments -n django-app 2>/dev/null || echo "No deployments found in django-app namespace"
    
    echo
    echo "🔗 Services:"
    kubectl get services -n django-app 2>/dev/null || echo "No services found in django-app namespace"
    
    echo
    echo "📊 Pods:"
    kubectl get pods -n django-app 2>/dev/null || echo "No pods found in django-app namespace"
    
    echo
    echo "📈 HPA Status:"
    kubectl get hpa -n django-app 2>/dev/null || echo "No HPA found in django-app namespace"
    
    echo
    echo "🔄 Argo CD Application:"
    kubectl get applications -n argocd 2>/dev/null | grep django-app || echo "Django app not found in Argo CD"
}

# Function to get service URLs
get_urls() {
    print_info "Service Access URLs"
    echo "=================="
    
    # Django App
    DJANGO_LB=$(kubectl get service django-app-django -n django-app -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")
    if [ -n "$DJANGO_LB" ]; then
        echo "🌐 Django App: http://$DJANGO_LB/admin/"
    else
        echo "🌐 Django App: http://localhost:8000 (kubectl port-forward svc/django-app-django 8000:80 -n django-app)"
    fi
    
    # Jenkins
    JENKINS_LB=$(kubectl get service jenkins -n jenkins -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")
    if [ -n "$JENKINS_LB" ]; then
        echo "🔧 Jenkins: http://$JENKINS_LB"
    else
        echo "🔧 Jenkins: http://localhost:8080 (kubectl port-forward svc/jenkins 8080:80 -n jenkins)"
    fi
    
    # Argo CD
    echo "🔄 Argo CD: https://localhost:8081 (kubectl port-forward svc/argocd-server 8081:443 -n argocd)"
    
    # Grafana
    echo "📊 Grafana: http://localhost:3000 (kubectl port-forward svc/prometheus-grafana 3000:80 -n monitoring)"
}

# Function to get credentials
get_credentials() {
    print_info "Service Credentials"
    echo "=================="
    
    echo "🔧 Jenkins Admin Password:"
    kubectl get secret jenkins -n jenkins -o jsonpath="{.data.jenkins-admin-password}" 2>/dev/null | base64 --decode 2>/dev/null || echo "Jenkins not found"
    echo
    
    echo "🔄 Argo CD Admin Password:"
    kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" 2>/dev/null | base64 -d 2>/dev/null || echo "Argo CD not found"
    echo
    
    echo "📊 Grafana Admin Password: admin123AWS"
    echo
}

# Function to deploy Django app manually
deploy_app() {
    local IMAGE_TAG=${1:-"latest"}
    local NAMESPACE=${2:-"django-app"}
    
    print_info "Deploying Django app with tag: $IMAGE_TAG to namespace: $NAMESPACE"
    
    # Get project root
    PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    # Check if Helm chart exists
    if [ ! -f "$PROJECT_ROOT/charts/django-app/Chart.yaml" ]; then
        print_error "Helm chart not found at $PROJECT_ROOT/charts/django-app/"
        exit 1
    fi
    
    # Deploy using Helm
    helm upgrade --install django-app "$PROJECT_ROOT/charts/django-app" \
        --namespace "$NAMESPACE" \
        --create-namespace \
        --set image.tag="$IMAGE_TAG" \
        --wait --timeout=300s
    
    print_success "Django app deployed successfully!"
    
    # Show status
    kubectl get pods -n "$NAMESPACE"
}

# Function to show logs
show_logs() {
    local NAMESPACE=${1:-"django-app"}
    
    print_info "Showing Django application logs from namespace: $NAMESPACE"
    
    if kubectl get deployment django-app-django -n "$NAMESPACE" &> /dev/null; then
        kubectl logs -f deployment/django-app-django -n "$NAMESPACE"
    else
        print_error "Django deployment not found in namespace: $NAMESPACE"
        exit 1
    fi
}

# Function to port-forward services
port_forward() {
    local SERVICE=$1
    
    case $SERVICE in
        django|app)
            print_info "Port-forwarding Django app to localhost:8000"
            kubectl port-forward svc/django-app-django 8000:80 -n django-app
            ;;
        jenkins)
            print_info "Port-forwarding Jenkins to localhost:8080"
            kubectl port-forward svc/jenkins 8080:80 -n jenkins
            ;;
        argocd|argo)
            print_info "Port-forwarding Argo CD to localhost:8081"
            kubectl port-forward svc/argocd-server 8081:443 -n argocd
            ;;
        grafana)
            print_info "Port-forwarding Grafana to localhost:3000"
            kubectl port-forward svc/prometheus-grafana 3000:80 -n monitoring
            ;;
        prometheus)
            print_info "Port-forwarding Prometheus to localhost:9090"
            kubectl port-forward svc/prometheus-kube-prometheus-prometheus 9090:9090 -n monitoring
            ;;
        *)
            print_error "Unknown service: $SERVICE"
            echo "Available services: django, jenkins, argocd, grafana, prometheus"
            exit 1
            ;;
    esac
}

# Function to show help
show_help() {
    echo "🚀 Django App Deployment Helper"
    echo "=============================="
    echo
    echo "Usage: $0 <command> [options]"
    echo
    echo "Commands:"
    echo "  status                     Show deployment status"
    echo "  urls                       Show service access URLs"
    echo "  credentials               Show service credentials"
    echo "  deploy [tag] [namespace]  Deploy Django app (default: latest, django-app)"
    echo "  logs [namespace]          Show application logs (default: django-app)"
    echo "  port-forward <service>    Port-forward service to localhost"
    echo "  help                      Show this help message"
    echo
    echo "Port-forward services:"
    echo "  django    - Django app (localhost:8000)"
    echo "  jenkins   - Jenkins (localhost:8080)"
    echo "  argocd    - Argo CD (localhost:8081)"
    echo "  grafana   - Grafana (localhost:3000)"
    echo "  prometheus - Prometheus (localhost:9090)"
    echo
    echo "Examples:"
    echo "  $0 status"
    echo "  $0 deploy latest django-app"
    echo "  $0 logs django-app"
    echo "  $0 port-forward django"
    echo
}

# Main script logic
case "${1:-help}" in
    status)
        check_kubectl
        show_status
        ;;
    urls)
        check_kubectl
        get_urls
        ;;
    credentials|creds)
        check_kubectl
        get_credentials
        ;;
    deploy)
        check_kubectl
        deploy_app "$2" "$3"
        ;;
    logs)
        check_kubectl
        show_logs "$2"
        ;;
    port-forward|pf)
        check_kubectl
        port_forward "$2"
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        print_error "Unknown command: $1"
        echo
        show_help
        exit 1
        ;;
esac
