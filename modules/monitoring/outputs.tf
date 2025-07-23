output "prometheus_service_name" {
  description = "Name of the Prometheus service"
  value       = "prometheus-kube-prometheus-prometheus"
}

output "grafana_service_name" {
  description = "Name of the Grafana service"
  value       = "prometheus-grafana"
}

output "alertmanager_service_name" {
  description = "Name of the Alertmanager service"
  value       = "prometheus-kube-prometheus-alertmanager"
}

output "namespace" {
  description = "Namespace where monitoring components are deployed"
  value       = var.namespace
}

output "grafana_admin_password" {
  description = "Grafana admin password"
  value       = var.grafana_admin_password
  sensitive   = true
}
