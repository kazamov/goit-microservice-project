# Django Helm Chart

This Helm chart deploys a Django application with PostgreSQL database on Kubernetes with autoscaling capabilities.

## Features

- **Django Deployment**: Django application from ECR with configurable replicas
- **PostgreSQL Database**: Bitnami PostgreSQL chart with persistent storage
- **Service**: LoadBalancer service for external access
- **ConfigMap**: Environment variables configuration
- **HPA**: Horizontal Pod Autoscaler for automatic scaling (2-6 replicas, CPU > 70%)
- **Resource Management**: CPU and memory requests/limits
- **Health Checks**: Database connectivity and application health endpoints
- **Database Migrations**: Automatic Django migrations on deployment
- **Init Container**: Waits for PostgreSQL before starting Django

## Prerequisites

- Kubernetes cluster (EKS)
- Helm 3.x
- kubectl configured for your cluster
- Docker image in ECR
- Storage class (gp2 for AWS EBS)

## Dependencies

This chart uses the Bitnami PostgreSQL chart as a dependency:
- **Repository**: https://charts.bitnami.com/bitnami
- **Chart**: postgresql
- **Version**: 16.7.18
- **PostgreSQL Version**: 17.5.0 (default for this chart version)

## Configuration

### Key Values

```yaml
image:
  repository: your-account.dkr.ecr.region.amazonaws.com/django_app
  tag: latest
  pullPolicy: IfNotPresent

service:
  type: LoadBalancer
  port: 8000

autoscaler:
  enabled: true
  minReplicas: 2
  maxReplicas: 6
  targetCPUUtilizationPercentage: 70

resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 500m
    memory: 512Mi

config:
  POSTGRES_HOST: "django-app-postgresql"
  POSTGRES_PORT: "5432"
  POSTGRES_USER: django_user
  POSTGRES_DB: django_db
  POSTGRES_PASSWORD: your_password
  DJANGO_DEBUG: "False"
  DJANGO_ALLOWED_HOSTS: "*"

# Bitnami PostgreSQL configuration
postgresql:
  enabled: true
  auth:
    postgresPassword: "postgres_admin_pass"
    username: "django_user"
    password: "pass9764gd"
    database: "django_db"
  primary:
    persistence:
      enabled: true
      size: 10Gi
      storageClass: "gp2"
    resources:
      requests:
        memory: 256Mi
        cpu: 250m
      limits:
        memory: 512Mi
        cpu: 500m
```

## Installation

### 1. Add Bitnami repository and update dependencies:
```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
helm dependency update
```

### 2. Install the chart:
```bash
helm install django-app .
```

### 3. Upgrade existing installation:
```bash
helm upgrade django-app .
```

### 4. Uninstall the chart:
```bash
helm uninstall django-app
```

## Monitoring

### Check deployment status:
```bash
kubectl get deployments
kubectl get services
kubectl get hpa
kubectl get pods
kubectl get pvc
```

### Get LoadBalancer URL:
```bash
kubectl get service django-app-django
```

### Check autoscaler status:
```bash
kubectl describe hpa django-app-django-hpa
```

### Test database connectivity:
```bash
# Access health check endpoint
curl http://<loadbalancer-url>/health/

# Check PostgreSQL directly
kubectl exec -it <postgresql-pod> -- psql -U django_user -d django_db
```

## Troubleshooting

### View logs:
```bash
kubectl logs -l app=django-app-django
kubectl logs -l app.kubernetes.io/name=postgresql
```

### Debug pods:
```bash
kubectl describe pod <pod-name>
```

### Check ConfigMap:
```bash
kubectl describe configmap django-app-config
```

### Test database connection:
```bash
kubectl exec -it <django-pod> -- python manage.py shell -c "from django.db import connections; connections['default'].cursor().execute('SELECT 1')"
```

## Security Notes

- Change default passwords in production
- Use Kubernetes secrets for sensitive data instead of ConfigMap
- Configure proper DJANGO_SECRET_KEY
- Set appropriate DJANGO_ALLOWED_HOSTS
- Consider enabling PostgreSQL metrics for monitoring

## Configuration

### Key Values

```yaml
image:
  repository: your-account.dkr.ecr.region.amazonaws.com/django_app
  tag: latest
  pullPolicy: IfNotPresent

service:
  type: LoadBalancer
  port: 8000

autoscaler:
  enabled: true
  minReplicas: 2
  maxReplicas: 6
  targetCPUUtilizationPercentage: 70

resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 500m
    memory: 512Mi

config:
  POSTGRES_HOST: db
  POSTGRES_PORT: "5432"
  POSTGRES_USER: django_user
  POSTGRES_DB: django_db
  POSTGRES_PASSWORD: your_password
  DJANGO_DEBUG: "False"
  DJANGO_ALLOWED_HOSTS: "*"
```

## Installation

### 1. Install the chart:
```bash
helm install django-app .
```

### 2. Upgrade existing installation:
```bash
helm upgrade django-app .
```

### 3. Uninstall the chart:
```bash
helm uninstall django-app
```

## Monitoring

### Check deployment status:
```bash
kubectl get deployments
kubectl get services
kubectl get hpa
kubectl get pods
```

### Get LoadBalancer URL:
```bash
kubectl get service django-app-django
```

### Check autoscaler status:
```bash
kubectl describe hpa django-app-django-hpa
```

## Autoscaling

The Horizontal Pod Autoscaler (HPA) is configured to:
- Maintain minimum 2 replicas
- Scale up to maximum 6 replicas
- Scale when CPU utilization exceeds 70%
- Requires resource requests to be defined (which are included)

## Troubleshooting

### View logs:
```bash
kubectl logs -l app=django-app-django
```

### Debug pods:
```bash
kubectl describe pod <pod-name>
```

### Check ConfigMap:
```bash
kubectl describe configmap django-app-config
```

## Security Notes

- Change default passwords in production
- Use Kubernetes secrets for sensitive data instead of ConfigMap
- Configure proper DJANGO_SECRET_KEY
- Set appropriate DJANGO_ALLOWED_HOSTS
