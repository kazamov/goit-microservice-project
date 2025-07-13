# AWS EKS Module

This module creates a complete Amazon Elastic Kubernetes Service (EKS) cluster with managed node groups. It provides a production-ready Kubernetes environment for running containerized applications with automatic scaling and management.

## Features

- ✅ EKS Cluster with API server endpoint configuration
- ✅ Managed Node Groups with auto-scaling
- ✅ IAM roles and policies for cluster and nodes
- ✅ Integration with VPC subnets
- ✅ ECR integration for container images
- ✅ Configurable instance types and scaling parameters
- ✅ Bootstrap cluster creator admin permissions
- ✅ Rolling update configuration

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        VPC                                  │
│                                                             │
│  ┌──────────────────┐              ┌──────────────────┐     │
│  │   Public Subnet  │              │  Private Subnet  │     │
│  │                  │              │                  │     │
│  │  ┌─────────────┐ │              │  ┌─────────────┐ │     │
│  │  │Load Balancer│ │              │  │ Worker Node │ │     │
│  │  └─────────────┘ │              │  └─────────────┘ │     │
│  └──────────────────┘              │  ┌─────────────┐ │     │
│                                    │  │ Worker Node │ │     │
│  ┌──────────────────┐              │  └─────────────┘ │     │
│  │   Public Subnet  │              └──────────────────┘     │
│  │                  │                                       │
│  │  ┌─────────────┐ │              ┌──────────────────┐     │
│  │  │ NAT Gateway │ │              │  Private Subnet  │     │
│  │  └─────────────┘ │              │                  │     │
│  └──────────────────┘              │  ┌─────────────┐ │     │
│           │                        │  │ Worker Node │ │     │
│    ┌─────────────┐                 │  └─────────────┘ │     │
│    │   EKS API   │                 └──────────────────┘     │
│    │   Server    │                                          │
│    └─────────────┘                                          │
└─────────────────────────────────────────────────────────────┘
                    │
              ┌─────────────┐
              │  Internet   │
              └─────────────┘
```

## Usage

### Basic Usage

```hcl
module "eks" {
  source       = "./modules/eks"
  cluster_name = "my-eks-cluster"
  subnet_ids   = module.vpc.private_subnets
  
  # Node group configuration
  instance_type = "t3.medium"
  desired_size  = 2
  min_size      = 1
  max_size      = 4
}
```

### Production Usage

```hcl
module "eks" {
  source       = "./modules/eks"
  cluster_name = "production-eks-cluster"
  region       = "eu-central-1"
  
  # Use both public and private subnets for flexibility
  subnet_ids = concat(
    module.vpc.public_subnets,
    module.vpc.private_subnets
  )
  
  # Production node group configuration
  instance_type = "t3.large"
  desired_size  = 3
  min_size      = 2
  max_size      = 10
}
```

### Multi-Environment Setup

```hcl
module "eks_dev" {
  source       = "./modules/eks"
  cluster_name = "dev-eks-cluster"
  subnet_ids   = module.vpc.private_subnets
  
  instance_type = "t3.small"
  desired_size  = 1
  min_size      = 1
  max_size      = 2
}

module "eks_prod" {
  source       = "./modules/eks"
  cluster_name = "prod-eks-cluster"
  subnet_ids   = module.vpc.private_subnets
  
  instance_type = "t3.xlarge"
  desired_size  = 5
  min_size      = 3
  max_size      = 20
}
```

## Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| cluster_name | Name of the EKS cluster | `string` | `example-eks-cluster` | yes |
| subnet_ids | List of subnet IDs for the EKS cluster | `list(string)` | n/a | yes |
| region | AWS region for deployment | `string` | `eu-central-1` | no |
| node_group_name | Name of the node group | `string` | `example-node-group` | no |
| instance_type | EC2 instance type for worker nodes | `string` | `t3.medium` | no |
| desired_size | Desired number of worker nodes | `number` | `2` | no |
| max_size | Maximum number of worker nodes | `number` | `3` | no |
| min_size | Minimum number of worker nodes | `number` | `1` | no |

## Outputs

| Name | Description |
|------|-------------|
| eks_cluster_endpoint | EKS API server endpoint for kubectl configuration |
| eks_cluster_name | Name of the created EKS cluster |
| eks_node_role_arn | IAM role ARN for EKS worker nodes |

## Resources Created

### EKS Cluster Resources
- **aws_eks_cluster**: Main EKS cluster with API server configuration
- **aws_iam_role** (cluster): IAM role for EKS cluster service
- **aws_iam_role_policy_attachment** (cluster): EKS cluster policy attachment

### Node Group Resources
- **aws_eks_node_group**: Managed node group with auto-scaling
- **aws_iam_role** (nodes): IAM role for EKS worker nodes
- **aws_iam_role_policy_attachment** (worker): Worker node policy attachments
- **aws_iam_role_policy_attachment** (cni): CNI plugin policy for networking
- **aws_iam_role_policy_attachment** (ecr): ECR read-only access for container images

## Instance Type Recommendations

### Development/Testing
```hcl
instance_type = "t3.small"   # 2 vCPU, 2 GB RAM - $15/month per node
desired_size  = 1
max_size      = 2
```

### Staging/Small Production
```hcl
instance_type = "t3.medium"  # 2 vCPU, 4 GB RAM - $30/month per node
desired_size  = 2
max_size      = 4
```

### Production
```hcl
instance_type = "t3.large"   # 2 vCPU, 8 GB RAM - $60/month per node
desired_size  = 3
max_size      = 10
```

### High-Performance Production
```hcl
instance_type = "t3.xlarge"  # 4 vCPU, 16 GB RAM - $120/month per node
desired_size  = 5
max_size      = 20
```

## Security Features

- ✅ **IAM Integration**: Proper IAM roles and policies for cluster and nodes
- ✅ **VPC Integration**: Cluster deployed within your private subnets
- ✅ **API Server Access**: Configurable public/private API server endpoints
- ✅ **ECR Integration**: Secure container image access from private registry
- ✅ **Network Policies**: Support for Kubernetes network policies
- ✅ **RBAC**: Role-based access control enabled by default

## Post-Deployment Setup

### 1. Configure kubectl

```bash
# Update kubeconfig
aws eks update-kubeconfig --region eu-central-1 --name your-cluster-name

# Verify connection
kubectl get nodes
```

### 2. Install AWS Load Balancer Controller

```bash
# Create IAM service account
eksctl create iamserviceaccount \
  --cluster=your-cluster-name \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --attach-policy-arn=arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess \
  --override-existing-serviceaccounts \
  --approve

# Install the controller
kubectl apply -k "github.com/aws/eks-charts/stable/aws-load-balancer-controller//crds?ref=master"
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=your-cluster-name \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller
```

### 3. Deploy Sample Application

```bash
# Deploy a simple nginx application
kubectl create deployment nginx --image=nginx
kubectl expose deployment nginx --port=80 --type=LoadBalancer
```

## Integration with ECR

The EKS nodes have built-in access to ECR repositories. To deploy from ECR:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
      - name: my-app
        image: <account-id>.dkr.ecr.eu-central-1.amazonaws.com/my-app:latest
        ports:
        - containerPort: 8080
```

## Monitoring and Logging

### Enable Container Insights
```bash
# Install CloudWatch agent
kubectl apply -f https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/latest/k8s-deployment-manifest-templates/deployment-mode/daemonset/container-insights-monitoring/quickstart/cwagent-fluentd-quickstart.yaml
```

### View Logs
```bash
# View cluster logs in CloudWatch
aws logs describe-log-groups --log-group-name-prefix /aws/eks/your-cluster-name
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Nodes not joining cluster | Check security groups and IAM roles |
| Pods stuck in Pending | Check node capacity and resource requests |
| Cannot connect to API server | Verify kubectl configuration and network access |
| ECR pull errors | Ensure nodes have ECR permissions |
| Load balancer not working | Install AWS Load Balancer Controller |

## Cost Optimization

### EKS Cluster Costs
- **Control Plane**: $0.10 per hour (~$73/month) per cluster
- **Worker Nodes**: Pay for EC2 instances based on type and count
- **Data Transfer**: Standard AWS data transfer charges apply

### Cost-Saving Tips
- Use Spot Instances for non-critical workloads
- Implement Cluster Autoscaler for dynamic scaling
- Use smaller instance types for development environments
- Enable node group scaling policies based on utilization

## Next Steps

After deploying EKS:
1. Configure monitoring with CloudWatch Container Insights
2. Set up centralized logging with Fluent Bit
3. Implement Horizontal Pod Autoscaler (HPA)
4. Deploy Cluster Autoscaler for node scaling
5. Set up Ingress controllers for traffic management
6. Configure persistent storage with EBS CSI driver

---

**For advanced configurations and best practices, refer to the [AWS EKS documentation](https://docs.aws.amazon.com/eks/).**
