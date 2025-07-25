# Django Application Deployment Guide

This guide explains how to deploy the Django application using both Jenkins CI/CD and Argo CD GitOps workflows.

## 🚀 Deployment Overview

The Django application can be deployed using two main approaches:

1. **Jenkins CI/CD Pipeline** - Traditional CI/CD with build, test, and deploy stages
2. **Argo CD GitOps** - Declarative GitOps workflow with automatic synchronization

## 📋 Prerequisites

- AWS EKS cluster deployed and configured
- Jenkins installed with proper IAM roles for ECR access
- Argo CD installed and configured
- ECR repository created for Django application
- RDS PostgreSQL database running

## 🔧 Jenkins CI/CD Pipeline

### Automatic Pipeline (Triggered by Git Push)

The main CI/CD pipeline is located in `django_app/Jenkinsfile` and includes:

**Stages:**
1. **Checkout & Setup** - Get source code and prepare environment
2. **Build & Push Docker Image** - Build with Kaniko and push to ECR
3. **Security Scan** - Security scanning (placeholder for tools like Trivy)
4. **Deploy to Development** - Automatic deployment (GitOps or Direct)
5. **Integration Tests** - Basic health checks and testing
6. **Notify Deployment** - Deployment notifications

**Environment Variables:**
- `ECR_REGISTRY`: ECR registry URL
- `IMAGE_NAME`: Docker image name (django_app)
- `IMAGE_TAG`: Generated tag (BUILD_NUMBER-GIT_COMMIT)
- `AUTO_DEPLOY`: Automatic deployment (true for main branch)
- `DEPLOYMENT_METHOD`: GitOps, Direct, or Manual
- `TARGET_NAMESPACE`: Kubernetes namespace (django-app)

**Triggers:**
- Automatic: Git push to any branch
- Main branch: Full CI/CD with deployment
- Other branches: Build and test only

### Manual Deployment Pipeline

For manual deployments, use the dedicated pipeline in `jenkins/ManualDeploy.Jenkinsfile`:

**Access:** 
- Jenkins → Django Project → Manual Django Deployment

**Parameters:**
- `IMAGE_TAG`: Docker image tag to deploy (required)
- `TARGET_NAMESPACE`: Kubernetes namespace (default: django-app)
- `DEPLOYMENT_TYPE`: 
  - **GitOps**: Updates Git repository for Argo CD sync
  - **Direct**: Direct deployment using Helm

**Use Cases:**
- Deploy specific image tags
- Rollback to previous versions
- Deploy to different environments
- Emergency deployments

## 🔄 Argo CD GitOps Workflow

### Automatic GitOps Deployment

Argo CD continuously monitors the Git repository and automatically deploys changes:

**Repository:** `https://github.com/kazamov/goit-microservice-project.git`
**Path:** `charts/django-app`
**Branch:** `final-project`

**Sync Policy:**
- **Automated:** True (automatic sync enabled)
- **Prune:** True (remove resources not in Git)
- **Self Heal:** True (fix configuration drift)
- **Create Namespace:** True (auto-create target namespace)

**Access Argo CD UI:**
```bash
kubectl port-forward svc/argocd-server 8081:443 -n argocd
# Open: https://localhost:8081
```

### GitOps Workflow Process

1. **Code Push** → Jenkins builds new image
2. **Image Tag Update** → Jenkins updates `values.yaml` in Git
3. **Argo CD Sync** → Argo CD detects changes and deploys
4. **Health Check** → Argo CD monitors application health

## 🛠️ Deployment Methods Comparison

| Method | Use Case | Speed | Rollback | Audit Trail | GitOps |
|--------|----------|-------|----------|-------------|---------|
| **Jenkins Direct** | Quick deploys, testing | Fast | Manual | Limited | ❌ |
| **Jenkins GitOps** | Production, compliance | Medium | Git-based | Full | ✅ |
| **Argo CD Auto** | Continuous deployment | Medium | Git-based | Full | ✅ |
| **Manual Deploy** | Specific versions | Fast | Manual | Limited | Optional |

## 📝 Configuration Files

### Django Helm Chart (`charts/django-app/`)

**Key Configuration Files:**
- `values.yaml` - Application configuration
- `templates/deployment.yaml` - Kubernetes deployment
- `templates/service.yaml` - Kubernetes service
- `templates/hpa.yaml` - Horizontal Pod Autoscaler

**Important Values:**
```yaml
image:
  repository: 127214174194.dkr.ecr.eu-central-1.amazonaws.com/django_app
  tag: latest  # Updated by Jenkins CI/CD

autoscaler:
  enabled: true
  minReplicas: 2
  maxReplicas: 6

config:
  POSTGRES_HOST: "myapp-db.czug8wokie9j.eu-central-1.rds.amazonaws.com"
  DJANGO_DEBUG: "False"
```

### Jenkins Configuration (`modules/jenkins/`)

**Service Account Permissions:**
- ECR push/pull access
- Kubernetes deployment access
- Git repository access

**Plugins Installed:**
- Kubernetes plugin for pod agents
- GitHub integration
- Docker workflow
- Pipeline plugins
- Blue Ocean UI

## 🚦 Deployment Workflows

### Scenario 1: Feature Development
```
1. Create feature branch
2. Push code → Jenkins builds image
3. Use Manual Deploy for testing
4. Merge to main → Auto-deploy via GitOps
```

### Scenario 2: Production Release
```
1. Tag release in Git
2. Jenkins builds tagged image
3. Update values.yaml with tag
4. Argo CD deploys automatically
5. Monitor via Grafana/Prometheus
```

### Scenario 3: Hotfix Deployment
```
1. Use Manual Deploy pipeline
2. Specify exact image tag
3. Choose Direct deployment for speed
4. Update Git repo afterward
```

### Scenario 4: Rollback
```
1. Identify last good image tag
2. Use Manual Deploy with previous tag
3. Or revert Git commit (for GitOps)
```

## 🔍 Monitoring and Troubleshooting

### Application Status
```bash
# Check deployment status
kubectl get deployments -n django-app

# Check pods
kubectl get pods -n django-app

# Check service
kubectl get service django-app-django -n django-app

# Check logs
kubectl logs -f deployment/django-app-django -n django-app
```

### Jenkins Pipeline Status
- Access Jenkins UI: `http://jenkins-lb-hostname`
- Check Blue Ocean for visual pipeline status
- Monitor build logs and artifacts

### Argo CD Application Status
- Access Argo CD UI: `https://localhost:8081`
- Monitor sync status and health
- View application topology

### Common Issues and Solutions

**Image Pull Errors:**
```bash
# Check ECR credentials
kubectl describe pod <pod-name> -n django-app

# Verify image exists
aws ecr describe-images --repository-name django_app
```

**Database Connection Issues:**
```bash
# Check RDS status
aws rds describe-db-instances --db-instance-identifier myapp-db

# Test connectivity from pod
kubectl exec -it <pod-name> -n django-app -- curl -v telnet://myapp-db.czug8wokie9j.eu-central-1.rds.amazonaws.com:5432
```

**Argo CD Sync Issues:**
```bash
# Force sync
argocd app sync django-app

# Check sync status
argocd app get django-app
```

## 🔐 Security Considerations

### Secrets Management
- Database credentials stored in Helm values (consider using Kubernetes secrets)
- GitHub tokens stored in Jenkins credentials
- ECR access via IAM roles (no hardcoded credentials)

### Network Security
- RDS in private subnets (publicly accessible for demo)
- Security groups restrict database access
- LoadBalancer services for controlled external access

### Image Security
- Kaniko builds without Docker daemon
- ECR image scanning enabled
- Base images from trusted sources

## 📈 Scaling and Performance

### Horizontal Pod Autoscaler
- CPU-based scaling (70% threshold)
- Memory-based scaling (80% threshold)
- Min replicas: 2, Max replicas: 6

### Resource Management
- CPU requests: 100m, limits: 500m
- Memory requests: 128Mi, limits: 512Mi
- Adjust based on load testing results

### Database Performance
- RDS PostgreSQL with appropriate instance class
- Connection pooling in Django settings
- Monitor via CloudWatch metrics

## 🎯 Best Practices

1. **Use GitOps for Production** - Ensures auditability and consistency
2. **Tag Releases** - Use semantic versioning for image tags
3. **Test Before Merge** - Use feature branches and testing
4. **Monitor Deployments** - Use Grafana dashboards for monitoring
5. **Implement Health Checks** - Proper liveness and readiness probes
6. **Secure Secrets** - Use Kubernetes secrets for sensitive data
7. **Resource Limits** - Always set appropriate resource requests/limits
8. **Backup Strategy** - Regular RDS backups and cluster backups

## 🔗 Useful Links

- **Jenkins UI:** `http://jenkins-lb-hostname`
- **Argo CD UI:** `https://localhost:8081` (port-forward required)
- **Grafana:** `http://localhost:3000` (port-forward required)
- **Django App:** `http://django-lb-hostname/admin/`
- **GitHub Repository:** `https://github.com/kazamov/goit-microservice-project`

## 📞 Support

For issues and questions:
1. Check Jenkins build logs
2. Review Argo CD sync status
3. Examine Kubernetes events: `kubectl get events -n django-app`
4. Check application logs: `kubectl logs -f deployment/django-app-django -n django-app`
