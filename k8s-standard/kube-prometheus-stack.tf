resource "random_string" "grafana_admin_password" {
  length  = 15
  special = false
}

resource "kubernetes_namespace" "kube-prometheus-stack" {
  metadata {
    name = var.kp_namespace
  }
}

locals {
  # strip trailing dot
  grafana_base_domain = replace(var.google_dns_managed_zone.dns_name, "/\\.$/", "")
  grafana_domain      = "grafana.${local.grafana_base_domain}"
}

resource "helm_release" "kube_prometheus_stack" {
  name = "kube-prometheus-stack"

  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "48.2.2"

  namespace = kubernetes_namespace.kube-prometheus-stack.metadata.0.name

  values = [
    templatefile("${path.module}/kube-prometheus-stack-values.yaml", {
      admin_password = random_string.grafana_admin_password.result
      domain         = local.grafana_domain
      loki_enabled   = var.loki_enabled
    })
  ]
}

resource "google_dns_record_set" "grafana" {
  name = "${local.grafana_domain}."
  type = "CNAME"
  ttl  = 300

  managed_zone = var.google_dns_managed_zone.name

  rrdatas = [
    google_dns_record_set.ingress_nginx.name
  ]
}

resource "kubernetes_config_map_v1" "loki_logs_dashboard" {
  count = var.loki_enabled ? 1 : 0

  metadata {
    name      = "loki-logs-dashboard-configmap"
    namespace = kubernetes_namespace.kube-prometheus-stack.metadata.0.name
    labels    = {
      grafana_dashboard = "1"
    }
  }
  data = {
    "loki_logs_dashboard.json" = file("${path.module}/loki_logs_dashboard.json")
  }
}

output "grafana" {
  value = {
    domain         = local.grafana_domain
    admin_username = "admin"
    admin_password = random_string.grafana_admin_password.result
  }
}
