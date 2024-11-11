variable "ingress_nginx_chart_version" {
  type    = string
  default = "4.7.1"
}

resource "kubernetes_namespace_v1" "ingress_nginx" {
  metadata {
    name = "ingress-nginx"
  }
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
        metrics = {
          enabled = true
          serviceMonitor = {
            enabled = true
          }
        }
        config = {
          enable-underscores-in-headers = true
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

output "ingress_ip" {
  value = data.kubernetes_service_v1.ingress_nginx.status.0.load_balancer.0.ingress.0.ip
}
