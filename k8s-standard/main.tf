variable "google_dns_managed_zone" {}

resource "kubernetes_namespace_v1" "ingress_nginx" {
  metadata {
    name = "ingress-nginx"
  }
}

resource "helm_release" "ingress_nginx" {
  name = "ingress-nginx"

  repository = "https://kubernetes.github.io/ingress-nginx"
  chart = "ingress-nginx"

  namespace = kubernetes_namespace_v1.ingress_nginx.metadata.0.name
}

data "kubernetes_service_v1" "ingress_nginx" {
  metadata {
    name = "${helm_release.ingress_nginx.name}-controller"
    namespace = kubernetes_namespace_v1.ingress_nginx.metadata.0.name
  }
}

resource "google_dns_record_set" "name" {
  name = "ingress-nginx.${var.google_dns_managed_zone.dns_name}"
  type = "A"
  ttl = 300

  managed_zone = var.google_dns_managed_zone.name

  rrdatas = [
    data.kubernetes_service_v1.ingress_nginx.status.0.load_balancer.0.ingress.0.ip
  ]
}

resource "kubernetes_namespace_v1" "cert_manager" {
  metadata {
    name = "cert-manager"
  }
}

resource "helm_release" "cert_manager" {
  name = "cert-manager"

  repository = "https://charts.jetstack.io"
  chart = "cert-manager"

  namespace = kubernetes_namespace_v1.cert_manager.metadata.0.name

  set {
    name = "installCRDs"
    value = "true"
  }
}

resource "kubernetes_manifest" "cluster_issuer" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind = "ClusterIssuer"
    metadata = {
      name = "letsencrypt"
    }
    spec = {
      acme = {
        server = "https://acme-v02.api.letsencrypt.org/directory"
        email = "admin@epoch8.co"
        privateKeySecretRef = {
          name = "letsencrypt"
        }
        solvers = [
          {
            http01 = {
              ingress = {
                class = "nginx"
              }
            }
          }
        ]
      }
    }
  }
}

output "ingress_dns" {
  value = google_dns_record_set.name.name
}
