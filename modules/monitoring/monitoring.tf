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
        "grafana.ini" = {
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

# Wait for Prometheus CRDs to be available
resource "time_sleep" "wait_for_prometheus_crds" {
  depends_on = [helm_release.prometheus]

  create_duration = "90s"
}

# Service Monitor for Django Application using null_resource to avoid CRD validation issues
resource "null_resource" "django_service_monitor" {
  provisioner "local-exec" {
    command = <<-EOF
      kubectl apply -f - <<YAML
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: django-app-monitor
  namespace: ${var.namespace}
  labels:
    app: django-app
spec:
  selector:
    matchLabels:
      app: django-app
  endpoints:
  - port: http
    path: /metrics
    interval: 30s
YAML
    EOF
  }

  provisioner "local-exec" {
    when    = destroy
    command = "kubectl delete servicemonitor django-app-monitor -n monitoring --ignore-not-found=true"
  }

  depends_on = [time_sleep.wait_for_prometheus_crds]
}
