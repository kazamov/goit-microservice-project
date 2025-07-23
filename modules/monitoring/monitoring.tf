# Prometheus and Grafana Monitoring Module

resource "helm_release" "prometheus" {
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace  = var.namespace
  version    = var.prometheus_chart_version

  create_namespace = true

  values = [
    yamlencode({
      prometheus = {
        prometheusSpec = {
          storageSpec = {
            volumeClaimTemplate = {
              spec = {
                storageClassName = "gp2"
                accessModes      = ["ReadWriteOnce"]
                resources = {
                  requests = {
                    storage = var.prometheus_storage_size
                  }
                }
              }
            }
          }
          retention = var.prometheus_retention
          resources = {
            requests = {
              memory = "1Gi"
              cpu    = "500m"
            }
            limits = {
              memory = "2Gi"
              cpu    = "1000m"
            }
          }
        }
      }
      grafana = {
        adminPassword = var.grafana_admin_password
        persistence = {
          enabled          = true
          size             = var.grafana_storage_size
          storageClassName = "gp2"
        }
        resources = {
          requests = {
            memory = "256Mi"
            cpu    = "250m"
          }
          limits = {
            memory = "512Mi"
            cpu    = "500m"
          }
        }
        grafana.ini = {
          server = {
            root_url = "http://localhost:3000"
          }
        }
      }
      alertmanager = {
        alertmanagerSpec = {
          storage = {
            volumeClaimTemplate = {
              spec = {
                storageClassName = "gp2"
                accessModes      = ["ReadWriteOnce"]
                resources = {
                  requests = {
                    storage = "2Gi"
                  }
                }
              }
            }
          }
          resources = {
            requests = {
              memory = "256Mi"
              cpu    = "100m"
            }
            limits = {
              memory = "512Mi"
              cpu    = "200m"
            }
          }
        }
      }
      nodeExporter = {
        enabled = true
      }
      kubeStateMetrics = {
        enabled = true
      }
    })
  ]

  depends_on = [var.depends_on_modules]
}

# Service Monitor for Django Application
resource "kubernetes_manifest" "django_service_monitor" {
  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "ServiceMonitor"
    metadata = {
      name      = "django-app-monitor"
      namespace = var.namespace
      labels = {
        app = "django-app"
      }
    }
    spec = {
      selector = {
        matchLabels = {
          app = "django-app"
        }
      }
      endpoints = [
        {
          port     = "http"
          path     = "/metrics"
          interval = "30s"
        }
      ]
    }
  }

  depends_on = [helm_release.prometheus]
}
