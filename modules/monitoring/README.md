# Monitoring Module

This module deploys Prometheus, Grafana, and Alertmanager for comprehensive monitoring of your Kubernetes cluster and applications.

## Features

- **Prometheus**: Metrics collection and storage
- **Grafana**: Visualization and dashboards
- **Alertmanager**: Alert routing and management
- **Node Exporter**: Node-level metrics
- **Kube State Metrics**: Kubernetes object metrics
- **Service Monitor**: Django application monitoring

## Resources Created

- Prometheus StatefulSet with persistent storage
- Grafana Deployment with persistent storage
- Alertmanager StatefulSet
- Node Exporter DaemonSet
- Kube State Metrics Deployment
- ServiceMonitor for Django app

## Usage

```hcl
module "monitoring" {
  source = "../modules/monitoring"
  
  namespace                 = "monitoring"
  prometheus_chart_version  = "51.2.0"
  prometheus_storage_size   = "10Gi"
  prometheus_retention      = "15d"
  grafana_admin_password    = "your_secure_password"
  grafana_storage_size      = "2Gi"
  
  depends_on_modules = [module.eks]
  
  providers = {
    helm       = helm
    kubernetes = kubernetes
  }
}
```

## Access Services

### Grafana
```bash
kubectl port-forward svc/prometheus-grafana 3000:80 -n monitoring
```
Access at: http://localhost:3000
- Username: admin
- Password: (value of grafana_admin_password)

### Prometheus
```bash
kubectl port-forward svc/prometheus-kube-prometheus-prometheus 9090:9090 -n monitoring
```
Access at: http://localhost:9090

### Alertmanager
```bash
kubectl port-forward svc/prometheus-kube-prometheus-alertmanager 9093:9093 -n monitoring
```
Access at: http://localhost:9093

## Default Dashboards

The kube-prometheus-stack comes with pre-configured dashboards for:
- Kubernetes cluster overview
- Node metrics
- Pod metrics
- Deployment metrics
- Network metrics
- Storage metrics

## Custom Metrics

The module includes a ServiceMonitor for Django applications that exposes metrics on `/metrics` endpoint.

## Storage

- Prometheus: Uses GP2 storage class with configurable size
- Grafana: Uses GP2 storage class with configurable size
- Data persists across pod restarts

## Security

- Grafana admin password is configurable and marked as sensitive
- Network policies can be added for additional security
- RBAC permissions are included in the chart
