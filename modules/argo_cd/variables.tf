variable "name" {
  description = "Name of the Argo CD release"
  type        = string
  default     = "argo-cd"
}

variable "namespace" {
  description = "Namespace for Argo CD"
  type        = string
  default     = "argocd"
}

variable "chart_version" {
  description = "Version of the Argo CD Helm chart"
  type        = string
  default     = "5.46.4"
}
