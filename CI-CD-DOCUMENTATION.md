# CI/CD Pipeline Documentation

## Architecture Overview

This project implements a complete CI/CD process using:

- **Jenkins** - for build and deployment automation
- **Kaniko** - for building Docker images in Kubernetes
- **Amazon ECR** - for storing Docker images
- **Helm** - for managing Kubernetes applications
- **Argo CD** - for automatic application synchronization
- **Terraform** - for Infrastructure as Code

## CI/CD Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Git Commit    │───▶│    Jenkins      │───▶│   Amazon ECR    │───▶│    Argo CD      │
│                 │    │                 │    │                 │    │                 │
│ • Source Code   │    │ • Build Image   │    │ • Store Image   │    │ • Deploy App    │
│ • Jenkinsfile   │    │ • Push to ECR   │    │ • Tagged Images │    │ • Auto Sync     │
│ • Dockerfile    │    │ • Update Chart  │    │ • Latest Tag    │    │ • Health Check  │
└─────────────────┘    └─────────────────┘    └─────────────────┘    └─────────────────┘
                                │                                               │
                                ▼                                               ▼
                       ┌─────────────────┐                            ┌─────────────────┐
                       │  Git Repository │◄───────────────────────────│  EKS Cluster    │
                       │                 │                            │                 │
                       │ • Helm Charts   │                            │ • Django Pods   │
                       │ • Updated Tags  │                            │ • PostgreSQL    │
                       │ • values.yaml   │                            │ • Services      │
                       └─────────────────┘                            └─────────────────┘
```

## Pipeline Components

### 1. Jenkins Pipeline (Jenkinsfile)

The pipeline consists of three main stages:

#### Stage 1: Checkout
- Gets git commit hash for tagging
- Forms unique image tag: `{BUILD_NUMBER}-{GIT_COMMIT_SHORT}`

#### Stage 2: Build & Push Docker Image
- Uses Kaniko for building Docker image
- Pushes image to Amazon ECR with two tags:
  - Unique tag: `{BUILD_NUMBER}-{GIT_COMMIT_SHORT}`
  - Latest tag: `latest`

#### Stage 3: Update Chart Tag in Git
- Clones Git repository
- Updates image tag in `charts/django-app/values.yaml`
- Commits changes with message `[skip ci]`
- Pushes changes to main branch

### 2. Argo CD Configuration

Argo CD is configured for:
- Tracking changes in Git repository
- Automatic synchronization when Helm charts change
- Creating namespaces when needed
- Self-healing when drift is detected

### 3. Helm Chart

Django application includes:
- **Deployment** with HPA (2-6 pods)
- **Service** of LoadBalancer type
- **ConfigMap** with environment variables
- **PostgreSQL** as dependency

## Deployment Process

### Step 1: Infrastructure Deployment

```bash
# Deploy backend (S3 + DynamoDB)
./deploy-ci-cd.sh
```

This script:
1. Deploys backend infrastructure
2. Deploys main infrastructure (VPC, ECR, EKS)
3. Installs Jenkins with Helm
4. Installs Argo CD with Helm
5. Configures kubectl context

### Step 2: Jenkins Configuration

```bash
# Automatic pipeline job creation
./configure-jenkins.sh
```

Or manually:
1. Open Jenkins UI
2. Create new Pipeline job
3. Specify Git repository and Jenkinsfile path
4. Configure GitHub webhook (optional)

### Step 3: Credentials Setup

In Jenkins you need to add:
- **github-token**: Username/Password credential for Git access

### Step 4: Pipeline Execution

1. Trigger build manually or through Git push
2. Jenkins builds image and updates Helm chart
3. Argo CD automatically picks up changes and deploys application

## Service Access

### Jenkins
- URL: `http://{JENKINS_LB_HOSTNAME}:80`
- Username: `admin`
- Password: `admin123`

### Argo CD
- URL: `https://{ARGOCD_LB_HOSTNAME}:443`
- Username: `admin`
- Password: get with command:
  ```bash
  kubectl get secret -n argocd argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
  ```

### Django Application
- URL: `http://{DJANGO_LB_HOSTNAME}:8000`

## Monitoring and Logs

### Jenkins
- Pipeline logs: Jenkins UI → job → Build History
- Agent logs: Jenkins UI → Manage Jenkins → System Logs

### Argo CD
- Application status: Argo CD UI → Applications
- Sync status and drift detection
- Resource health monitoring

### Kubernetes
```bash
# Pod logs
kubectl logs -n django-app deployment/django-app

# Service status
kubectl get svc -n django-app

# HPA status
kubectl get hpa -n django-app
```

## Troubleshooting

### Common Issues:

1. **Jenkins pod doesn't start**
   - Check storage class
   - Check IAM permissions for service account

2. **Kaniko can't push to ECR**
   - Check IRSA configuration
   - Check ECR permissions

3. **Argo CD doesn't sync**
   - Check Git repository access
   - Check Helm chart syntax

4. **Django pods in CrashLoopBackOff state**
   - Check PostgreSQL connectivity
   - Check environment variables

### Useful Commands:

```bash
# Restart Jenkins
kubectl rollout restart deployment -n jenkins jenkins

# Force Argo CD sync
kubectl patch app django-app -n argocd -p '{"spec":{"syncPolicy":{"automated":null}}}' --type merge
kubectl patch app django-app -n argocd -p '{"operation":{"sync":{}}}' --type merge

# Check ECR images
aws ecr describe-images --repository-name django_app --region eu-central-1
```

## Security

- Jenkins uses IRSA for ECR access
- Secrets are stored in Kubernetes Secrets
- Git credentials are managed through Jenkins credentials store
- Argo CD uses RBAC for access control

## Scaling

- HPA automatically scales pods based on CPU
- EKS cluster can scale through Cluster Autoscaler
- PostgreSQL can be replaced with Amazon RDS for production

## Backup and Recovery

- Terraform state is stored in S3 with versioning
- Jenkins configuration as code allows restoration
- Argo CD Applications can be restored from Git
- PostgreSQL data is stored in EBS volumes
