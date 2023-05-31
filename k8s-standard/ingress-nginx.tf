resource "kubernetes_namespace_v1" "ingress_nginx" {
  metadata {
    name = "ingress-nginx"
  }
}

resource "helm_release" "ingress_nginx" {
  name = "ingress-nginx"

  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"

  namespace = kubernetes_namespace_v1.ingress_nginx.metadata.0.name
}

data "kubernetes_service_v1" "ingress_nginx" {
  metadata {
    name      = "${helm_release.ingress_nginx.name}-controller"
    namespace = kubernetes_namespace_v1.ingress_nginx.metadata.0.name
  }
}

locals {
  ingress_base_domain = replace(var.google_dns_managed_zone.dns_name, "/\\.$/", "")
  ingress_domain = "ingress-nginx.${local.ingress_base_domain}"
}

resource "google_dns_record_set" "ingress_nginx" {
  name = "${local.ingress_domain}."
  type = "A"
  ttl  = 300

  managed_zone = var.google_dns_managed_zone.name

  rrdatas = [
    data.kubernetes_service_v1.ingress_nginx.status.0.load_balancer.0.ingress.0.ip
  ]
}

output "ingress_dns" {
  value = google_dns_record_set.ingress_nginx.name
}
