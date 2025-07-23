variable "namespace" {
  description = "Kubernetes namespace for monitoring components"
  type        = string
  default     = "monitoring"
}

variable "prometheus_chart_version" {
  description = "Version of the kube-prometheus-stack chart"
  type        = string
  default     = "51.2.0"
}

variable "prometheus_storage_size" {
  description = "Storage size for Prometheus data"
  type        = string
  default     = "10Gi"
}

variable "prometheus_retention" {
  description = "Prometheus data retention period"
  type        = string
  default     = "15d"
}

variable "grafana_admin_password" {
  description = "Admin password for Grafana"
  type        = string
  default     = "admin123"
  sensitive   = true
}

variable "grafana_storage_size" {
  description = "Storage size for Grafana"
  type        = string
  default     = "2Gi"
}

variable "depends_on_modules" {
  description = "List of modules this monitoring setup depends on"
  type        = list(any)
  default     = []
}
