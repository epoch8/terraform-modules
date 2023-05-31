resource "random_string" "grafana_admin_password" {
  length  = 15
  special = false
}

resource "kubernetes_namespace" "kube-prometheus-stack" {
  metadata {
    name = "kube-prometheus-stack"
  }
}

locals {
  # strip trailing dot
  grafana_base_domain = replace(var.google_dns_managed_zone.dns_name, "/\\.$/", "")
  grafana_domain = "grafana.${local.grafana_base_domain}"
}

resource "helm_release" "kube_prometheus_stack" {
  name = "kube-prometheus-stack"

  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "46.5.0"

  namespace = kubernetes_namespace.kube-prometheus-stack.metadata.0.name

  values = [
    templatefile("${path.module}/kube-prometheus-stack-values.yaml", {
      admin_password = random_string.grafana_admin_password.result
      domain         = local.grafana_domain
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

output "grafana" {
  value = {
    domain = local.grafana_domain
    admin_username = "admin"
    admin_password = random_string.grafana_admin_password.result
  }
}
