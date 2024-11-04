variable "ingress_nginx_chart_version" {
  type    = string
  default = "4.7.1"
}

resource "kubernetes_namespace_v1" "ingress_nginx" {
  metadata {
    name = "ingress-nginx"
  }
}

variable "ingress_nginx_type" {
  type    = string
  default = "LoadBalancer"
}

resource "helm_release" "ingress_nginx" {
  name = "ingress-nginx"

  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = var.ingress_nginx_chart_version

  namespace = kubernetes_namespace_v1.ingress_nginx.metadata.0.name

  values = [
    jsonencode({
      controller = {
        resources   = var.nginx_resources
        autoscaling = {
          enabled = true
        }
        config = {
          enable-underscores-in-headers = true
        }
        service = {
          type = var.ingress_nginx_type
        }
      }
    }),
  ]
}

data "kubernetes_service_v1" "ingress_nginx" {
  metadata {
    name      = "${helm_release.ingress_nginx.name}-controller"
    namespace = kubernetes_namespace_v1.ingress_nginx.metadata.0.name
  }
}

locals {
  ingress_domain = "ingress-nginx.${var.base_domain}"
}
