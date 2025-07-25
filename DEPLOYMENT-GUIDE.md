# Django Application Deployment Guide

This guide explains how to deploy the complete infrastructure and Django application using Jenkins CI/CD pipeline and Argo CD GitOps workflow.

## 🚀 Deployment Overview

The deployment process consists of three main stages:

1. **Infrastructure Deployment** - Deploy AWS infrastructure with CI/CD components
2. **Jenkins CI/CD Pipeline** - Builds Docker images and pushes to ECR
3. **Argo CD GitOps** - Deploys applications from Git repository

## 📋 Prerequisites

- AWS CLI configured with appropriate permissions
- Terraform >= 1.0
- kubectl
- Helm >= 3.0
- Docker
- GitHub repository with Django application code

## 🏗️ Infrastructure Deployment

### Quick Deployment

For a complete one-command deployment of all infrastructure and CI/CD components:

```bash
# Deploy complete infrastructure
./deploy.sh
```

This script will:
1. Deploy backend infrastructure (S3 + DynamoDB for Terraform state)
2. Deploy main infrastructure (VPC + EKS + RDS + ECR)
3. Install Jenkins CI/CD platform
4. Install Argo CD GitOps platform
5. Install monitoring stack (Prometheus + Grafana)
6. Deploy Django application with PostgreSQL

### Manual Step-by-Step Deployment

```bash
# 1. Deploy backend infrastructure
cd infra-backend
terraform init && terraform apply

# 2. Deploy main infrastructure
cd ../main-infra
terraform init && terraform apply

# 3. Configure kubectl
aws eks update-kubeconfig --region eu-central-1 --name eks-cluster-demo
```

### Validation

After deployment, validate that everything is working:

```bash
# Comprehensive validation of all components
./validate.sh
```

This will check:
- Infrastructure components (VPC, EKS, RDS, ECR)
- CI/CD services (Jenkins, Argo CD)
- Monitoring stack (Prometheus, Grafana)
- Django application health and connectivity

## 🔧 Jenkins Build Job Configuration

**Note:** If you used `./deploy.sh`, Jenkins is already configured with a basic pipeline. The following steps are for custom configuration.

### Step 1: Access Jenkins

1. **Get Jenkins URL:**
   ```bash
   kubectl get svc -n jenkins jenkins -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
   ```

2. **Access Jenkins UI:**
   ```
   http://<jenkins-loadbalancer-hostname>
   Username: admin
   Password: admin123
   ```

### Step 2: Create Jenkins Pipeline Job

1. **Create New Job:**
   - Click "New Item"
   - Enter job name: `django-app-pipeline`
   - Select "Pipeline"
   - Click "OK"

2. **Configure Pipeline:**
   - In "Pipeline" section, select "Pipeline script from SCM"
   - SCM: Git
   - Repository URL: `https://github.com/kazamov/goit-microservice-project.git`
   - Branch: `*/final-project`
   - Script Path: `django_app/Jenkinsfile`

3. **Configure GitHub Credentials:**
   - Go to "Manage Jenkins" → "Manage Credentials"
   - Add credential:
     - Kind: Username with password
     - ID: `github-token`
     - Username: Your GitHub username
     - Password: Your GitHub Personal Access Token

### Step 3: Jenkins Pipeline Stages

The pipeline (`django_app/Jenkinsfile`) includes these stages:

**1. Checkout & Setup**
- Gets Git commit hash for unique image tagging
- Sets build configuration variables

**2. Build & Push Docker Image**
- Uses Kaniko to build Django Docker image
- Tags image with: `{BUILD_NUMBER}-{GIT_COMMIT_SHORT}`
- Pushes to ECR repository: `127214174194.dkr.ecr.eu-central-1.amazonaws.com/django_app`

**3. Security Scan (Optional)**
- Placeholder for security scanning tools
- Only runs on main branch

**4. Deploy to Development**
- **GitOps Mode**: Updates `charts/django-app/values.yaml` in Git
- **Direct Mode**: Deploys directly using Helm
- Only runs for main branch with AUTO_DEPLOY=true

**5. Integration Tests**
- Waits for deployment readiness
- Performs basic health checks

### Step 4: Pipeline Environment Variables

Key variables in the Jenkinsfile:

```groovy
ECR_REGISTRY = "127214174194.dkr.ecr.eu-central-1.amazonaws.com"
IMAGE_NAME   = "django_app"
IMAGE_TAG    = "${env.BUILD_NUMBER}-${env.GIT_COMMIT.take(7)}"
AUTO_DEPLOY  = "${env.BRANCH_NAME == 'main' ? 'true' : 'false'}"
DEPLOYMENT_METHOD = "GitOps"  // Options: GitOps, Direct, Manual
TARGET_NAMESPACE = "django-app"
```

### Step 5: Trigger Build

1. **Manual Trigger:**
   - Go to your Jenkins job
   - Click "Build Now"

2. **Automatic Trigger (Optional):**
   - Configure GitHub webhook in repository settings
   - Webhook URL: `http://<jenkins-hostname>/github-webhook/`

## 🔄 Argo CD GitOps Configuration

**Note:** If you used `./deploy.sh`, Argo CD is already configured with the Django application. The following steps are for manual configuration or troubleshooting.

### Step 1: Access Argo CD

1. **Port Forward to Argo CD:**
   ```bash
   kubectl port-forward svc/argocd-server 8080:443 -n argocd
   ```

2. **Access UI:**
   ```
   https://localhost:8080
   Username: admin
   Password: $(kubectl get secret -n argocd argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d)
   ```

### Step 2: Django Application Sync

The Django application is already configured in Argo CD with these settings:

**Application Configuration:**
- **Name:** django-app
- **Project:** default
- **Source Repository:** https://github.com/kazamov/goit-microservice-project.git
- **Path:** charts/django-app
- **Target Branch:** final-project
- **Destination Cluster:** in-cluster
- **Namespace:** django-app

**Sync Policy:**
- **Automated Sync:** Enabled
- **Prune Resources:** Enabled (removes resources not in Git)
- **Self Heal:** Enabled (corrects configuration drift)
- **Create Namespace:** Enabled

### Step 3: Manual Sync Process

1. **Access Application:**
   - In Argo CD UI, click on "django-app" application

2. **Trigger Sync:**
   - Click "SYNC" button
   - Configure sync options if needed:
     - **Prune:** Remove resources not in Git
     - **Dry Run:** Preview changes only
     - **Force:** Override certain protections
   - Click "SYNCHRONIZE"

3. **Monitor Sync Progress:**
   - Watch the application tree view update
   - Check for any error messages
   - Verify health status changes to "Healthy"

### Step 4: Automatic Sync Behavior

When Jenkins updates `charts/django-app/values.yaml`:

1. **Git Commit** → Jenkins pushes new image tag to values.yaml
2. **Argo CD Detection** → Detects repository changes (within 3 minutes)
3. **Automatic Sync** → Applies changes to Kubernetes cluster
4. **Health Check** → Monitors pod health and readiness

## 🔄 Complete Deployment Workflow

### Development Workflow

1. **Code Changes:**
   ```bash
   git checkout -b feature/new-feature
   # Make changes to Django app
   git commit -m "Add new feature"
   git push origin feature/new-feature
   ```

2. **Jenkins Build:**
   - Jenkins automatically builds image for feature branch
   - Image tagged but not deployed (AUTO_DEPLOY=false)

3. **Manual Testing:**
   - Use Manual Deploy pipeline in Jenkins if needed
   - Test specific image tags in development environment

4. **Merge to Main:**
   ```bash
   git checkout main
   git merge feature/new-feature
   git push origin main
   ```

5. **Automatic Deployment:**
   - Jenkins builds image with main branch tag
   - Updates values.yaml with new image tag
   - Argo CD automatically syncs and deploys

### Production Deployment

1. **Tag Release:**
   ```bash
   git tag -a v1.0.0 -m "Release version 1.0.0"
   git push origin v1.0.0
   ```

2. **Jenkins Build:**
   - Builds image with version tag
   - Updates production values.yaml

3. **Argo CD Sync:**
   - Automatically deploys tagged version
   - Monitors application health

### Rollback Process

1. **Identify Last Good Version:**
   ```bash
   # Check Git history
   git log --oneline charts/django-app/values.yaml
   
   # Check Argo CD sync history in UI
   ```

2. **Rollback Options:**
   
   **Option A - Git Revert:**
   ```bash
   git revert <commit-hash>
   git push origin main
   # Argo CD will automatically sync the revert
   ```
   
   **Option B - Manual Deploy:**
   - Use Jenkins Manual Deploy pipeline
   - Specify previous working image tag
   - Choose Direct deployment for speed

3. **Verify Rollback:**
   - Check Argo CD application status
   - Verify application health and functionality

## 🔍 Monitoring and Troubleshooting

### Check Deployment Status

```bash
# Check Django pods
kubectl get pods -n django-app

# Check service and LoadBalancer
kubectl get svc -n django-app

# Check application logs
kubectl logs -f deployment/django-app-django -n django-app

# Check events
kubectl get events -n django-app --sort-by='.lastTimestamp'
```

### Jenkins Pipeline Issues

1. **Build Failures:**
   - Check Jenkins build logs
   - Verify ECR permissions and image repository
   - Check GitHub credentials

2. **Image Push Issues:**
   - Verify IAM roles for Jenkins service account
   - Check ECR repository permissions

### Argo CD Sync Issues

1. **Sync Failures:**
   - Check Argo CD application logs
   - Verify Git repository access
   - Check Helm chart syntax

2. **Health Check Failures:**
   - Verify pod readiness and liveness probes
   - Check service and ingress configurations
   - Review application logs

### Common Solutions

**Database Connection Issues:**
```bash
# Test database connectivity
kubectl exec -it <pod-name> -n django-app -- python manage.py shell -c "
from django.db import connection
cursor = connection.cursor()
cursor.execute('SELECT 1')
print('Database connected successfully')
"
```

**Port Configuration Issues:**
```bash
# Check service configuration
kubectl describe svc django-app-django -n django-app

# Verify container ports match service targetPort
kubectl describe deployment django-app-django -n django-app
```

## 🔐 Security and Best Practices

### Security Configuration

1. **IAM Roles:** Jenkins uses IRSA for ECR access (no hardcoded credentials)
2. **GitHub Access:** Personal Access Token stored in Jenkins credentials
3. **Database:** Connection details in Helm values (consider Kubernetes secrets)
4. **Container Security:** Non-root user, minimal base image

### Best Practices

1. **GitOps First:** Use GitOps for all production deployments
2. **Immutable Tags:** Tag releases with semantic versioning
3. **Resource Limits:** Always set CPU/memory requests and limits
4. **Health Checks:** Implement proper readiness and liveness probes
5. **Monitoring:** Monitor application metrics and logs
6. **Backup:** Regular database backups and cluster state backups

## 📊 Application Access

After successful deployment:

- **Django Application:** `http://<django-loadbalancer-hostname>/`
- **Django Admin:** `http://<django-loadbalancer-hostname>/admin/`
- **Health Check:** `http://<django-loadbalancer-hostname>/health/`

Get LoadBalancer hostname:
```bash
kubectl get svc django-app-django -n django-app -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

## 🧹 Cleanup

When you're finished with the infrastructure and want to remove all resources:

### Complete Cleanup

```bash
# Remove all infrastructure and applications
./cleanup.sh
```

This script will safely:
1. Remove Django application from Kubernetes
2. Delete Argo CD applications and configurations
3. Remove Jenkins and its persistent volumes
4. Clean up monitoring stack
5. Destroy main infrastructure (EKS, RDS, VPC, etc.)
6. Destroy backend infrastructure (S3 bucket, DynamoDB table)

### Manual Cleanup

If you prefer manual cleanup or need to troubleshoot:

```bash
# 1. Remove applications first
helm uninstall django-app -n django-app || true
kubectl delete namespace django-app || true

# 2. Remove CI/CD and monitoring
helm uninstall jenkins -n jenkins || true
helm uninstall argocd -n argocd || true
helm uninstall prometheus -n monitoring || true

# 3. Destroy main infrastructure
cd main-infra
terraform destroy

# 4. Destroy backend infrastructure (optional)
cd ../infra-backend
terraform destroy
```

### Validation After Cleanup

```bash
# Verify all resources are removed
./validate.sh --cleanup-mode
```

**Note:** The cleanup process is designed to be safe and will prompt for confirmation before destroying resources. Always backup any important data before running cleanup operations.


