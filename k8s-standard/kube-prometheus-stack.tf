variable "kube_prometheus_stack_enabled" {
  type    = bool
  default = true
}

variable "kube_prometheus_stack_version" {
  type    = string
  default = "70.7.0"
}

variable "prometheus_resources" {
  type = object({
    requests = object({
      cpu    = string
      memory = string
    })
    limits = object({
      cpu    = string
      memory = string
    })
  })

  default = null
}

resource "random_string" "grafana_admin_password" {
  count = var.kube_prometheus_stack_enabled ? 1 : 0

  length  = 15
  special = false
}

resource "kubernetes_namespace" "kube-prometheus-stack" {
  count = var.kube_prometheus_stack_enabled ? 1 : 0

  metadata {
    name = var.kp_namespace
  }
}

locals {
  grafana_domain = "grafana.${var.base_domain}"
}

resource "kubernetes_priority_class_v1" "high_priority" {
  count = var.kube_prometheus_stack_enabled ? 1 : 0

  metadata {
    name = "high-priority-monitoring"
  }

  global_default = false

  value = 1000000
}

resource "helm_release" "kube_prometheus_stack" {
  count = var.kube_prometheus_stack_enabled ? 1 : 0

  name = "kube-prometheus-stack"

  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = var.kube_prometheus_stack_version

  namespace = kubernetes_namespace.kube-prometheus-stack[0].metadata.0.name

  values = [
    templatefile("${path.module}/kube-prometheus-stack-values.yaml", {
      admin_password = random_string.grafana_admin_password[0].result
      domain         = local.grafana_domain
      loki_enabled   = var.loki_enabled
      gke_mode       = var.gke_mode
      priority_class = kubernetes_priority_class_v1.high_priority[0].metadata.0.name

      prometheus_resources = var.prometheus_resources
    })
  ]
}

resource "kubernetes_config_map_v1" "loki_logs_dashboard" {
  count = (var.loki_enabled && var.kube_prometheus_stack_enabled) ? 1 : 0

  metadata {
    name      = "loki-logs-dashboard-configmap"
    namespace = kubernetes_namespace.kube-prometheus-stack[0].metadata.0.name
    labels = {
      grafana_dashboard = "1"
    }
  }
  data = {
    "loki_logs_dashboard.json" = file("${path.module}/loki_logs_dashboard.json")
  }
}

output "grafana" {
  value = {
    domain         = var.kube_prometheus_stack_enabled ? local.grafana_domain : null
    admin_username = var.kube_prometheus_stack_enabled ? "admin" : null
    admin_password = var.kube_prometheus_stack_enabled ? random_string.grafana_admin_password[0].result : null
  }
}
