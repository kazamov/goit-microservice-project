# 🎯 GoIT Microservice Final Project - Complete Guide

Welcome! This is a complete toolkit for executing the final microservice architecture project on AWS.

## 📋 Project Documentation

### 🚀 Main files for project execution
1. **[FINAL-PROJECT-INSTRUCTIONS.md](./FINAL-PROJECT-INSTRUCTIONS.md)** - Detailed step-by-step instructions
2. **[FINAL-PROJECT-CHECKLIST.md](./FINAL-PROJECT-CHECKLIST.md)** - Assessment checklist (100 points)
3. **[README.md](./README.md)** - General project information

### 🛠️ Automation scripts
1. **[deploy-final-project.sh](./deploy-final-project.sh)** - Automatic deployment of entire infrastructure
2. **[validate-final-project.sh](./validate-final-project.sh)** - Validation of all components
3. **[cleanup-final-project.sh](./cleanup-final-project.sh)** - Safe resource cleanup

## 🏆 Technical Requirements and Assessment Criteria

### Components to be implemented:
- ✅ **VPC** - Network infrastructure with public/private subnets
- ✅ **EKS** - Kubernetes cluster with auto-scaling
- ✅ **RDS** - PostgreSQL database with Multi-AZ
- ✅ **ECR** - Docker registry for images
- ✅ **Jenkins** - CI/CD pipeline with automated builds
- ✅ **Argo CD** - GitOps deployment with synchronization
- ✅ **Prometheus** - Metrics collection and monitoring
- ✅ **Grafana** - Visualization and dashboards

## 🚀 Quick Start

### Option 1: Automated deployment (recommended)
```bash
# 1. Ensure AWS CLI is configured
aws configure

# 2. Run automated deployment
./deploy-final-project.sh

# 3. Validate results
./validate-final-project.sh
```

### Option 2: Step-by-step deployment
```bash
# 1. Backend infrastructure
cd infra-backend
terraform init && terraform apply

# 2. Main infrastructure  
cd ../main-infra
terraform init && terraform apply

# 3. Configure kubectl
aws eks update-kubeconfig --region eu-central-1 --name eks-cluster-demo

# 4. Build and deploy application
cd ../django_app
# (see detailed instructions in FINAL-PROJECT-INSTRUCTIONS.md)
```

## 🔧 Service Access

### Access commands:
```bash
# Jenkins CI/CD
kubectl port-forward svc/jenkins 8080:8080 -n jenkins

# Argo CD GitOps  
kubectl port-forward svc/argocd-server 8081:443 -n argocd

# Grafana Monitoring
kubectl port-forward svc/prometheus-grafana 3000:80 -n monitoring

# Prometheus Metrics
kubectl port-forward svc/prometheus-kube-prometheus-prometheus 9090:9090 -n monitoring
```

### Authentication:
```bash
# Jenkins password
kubectl get secret jenkins -n jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode

# Argo CD password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Grafana: admin / admin123AWS
```

## 📊 Project Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        AWS Infrastructure                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Backend (S3+DynamoDB) ──► Main Infrastructure                  │
│                            ┌─────────────────────────────────┐  │
│                            │            VPC                  │  │
│                            │  ┌─────────────────────────────┐│  │
│                            │  │        EKS Cluster         ││  │
│                            │  │                            ││  │
│                            │  │  Jenkins ── Argo CD       ││  │
│                            │  │     │         │           ││  │
│                            │  │     ▼         ▼           ││  │
│                            │  │  Django App (HPA 2-6)     ││  │
│                            │  │                            ││  │
│                            │  │  Prometheus ── Grafana    ││  │
│                            │  └─────────────────────────────┘│  │
│                            │                                 │  │
│                            │  ECR ──── RDS PostgreSQL       │  │
│                            └─────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

## 🎯 Execution Stages

1. **Preparation** - Check tools and AWS access
2. **Backend** - Deploy S3 and DynamoDB for Terraform state
3. **Infrastructure** - VPC, EKS, RDS, ECR
4. **Services** - Jenkins, Argo CD, Prometheus, Grafana
5. **Application** - Django app with Helm chart
6. **Testing** - Validate all components
7. **Documentation** - Finalize documentation

## 📚 Additional Resources

### Useful diagnostic commands:
```bash
# Cluster status
kubectl get nodes
kubectl get pods --all-namespaces

# Service logs
kubectl logs -f deployment/jenkins -n jenkins
kubectl logs -f deployment/argocd-server -n argocd

# Resource monitoring
kubectl top nodes
kubectl top pods --all-namespaces
```

### Troubleshooting:
- **Pods not starting**: `kubectl describe pod <pod-name>`
- **Services unavailable**: `kubectl get svc --all-namespaces`
- **HPA not working**: `kubectl describe hpa <hpa-name>`
- **Prometheus not collecting metrics**: `kubectl get servicemonitors -n monitoring`

## 🧹 Resource Cleanup

```bash
# Complete cleanup of all resources
./cleanup-final-project.sh

# Or step-by-step:
cd main-infra && terraform destroy
cd ../infra-backend && terraform destroy
```

## ✅ Final Validation

Before project submission, ensure:

1. ✅ All services are running and accessible
2. ✅ HPA is working (load testing)
3. ✅ Monitoring shows metrics
4. ✅ CI/CD pipeline is functional
5. ✅ Documentation is complete and clear
6. ✅ Can perform cleanup and re-deploy

## 🎉 Success!

After completing all steps, you will have:
- Fully functional microservice infrastructure on AWS
- CI/CD pipeline with Jenkins and Argo CD
- Comprehensive monitoring with Prometheus and Grafana
- Auto-scaling Django application
- Production-ready security configuration

**Congratulations on successfully completing the final project! 🚀**

---

## 📞 Support

If you have questions:
1. Check [FINAL-PROJECT-INSTRUCTIONS-EN.md](./FINAL-PROJECT-INSTRUCTIONS-EN.md) for detailed instructions
2. Run `./validate-final-project.sh` for diagnostics
3. Check service logs with kubectl commands
4. Consult [FINAL-PROJECT-CHECKLIST-EN.md](./FINAL-PROJECT-CHECKLIST-EN.md) for self-assessment
