terraform {
  required_providers {
    helm = {}
  }
}

variable "project" {
  type = string
}

variable "k8s_namespace" {
  type = string
}

variable "base_domain" {
  type = string
  # "XXX.epoch8.co"
}

######################

resource "random_string" "api_key" {
  length  = 16
  special = false
}

resource "helm_release" "qdrant" {
  name = "${var.project}-qdrant"

  repository = "https://qdrant.github.io/qdrant-helm"
  chart      = "qdrant"
  version    = "0.3.0"

  namespace = var.k8s_namespace

  values = [
    <<EOF
    resources:
      requests:
        cpu: 0.1
        memory: 2Gi
      limits:
        cpu: 1
        memory: 2Gi

    ingress:
      enabled: true

      annotations:
        kubernetes.io/ingress.class: nginx
        cert-manager.io/cluster-issuer: letsencrypt
        nginx.ingress.kubernetes.io/proxy-body-size: 100m
      
      hosts:
        - host: qdrant.${var.project}.${var.base_domain}
          paths:
            - path: /
              pathType: Prefix
              servicePort: 6333        

      tls:
        - hosts:
            - qdrant.${var.project}.${var.base_domain}
          secretName: ${var.project}-qdrant-tls

    config:
      service:
        api_key: ${random_string.api_key.result}
    EOF
  ]
}

output "dns" {
  value = "qdrant.${var.project}.${var.base_domain}"
}

output "config" {
  value = {
    host    = "qdrant.${var.project}.${var.base_domain}"
    api_key = random_string.api_key.result
  }
}
