terraform {
  required_providers {
    helm = {}
  }
}

variable "name_prefix" {
  type = string
}

variable "k8s_namespace" {
  type = string
}

variable "ingress_enabled" {
  type = bool
  default = false
}

variable "base_domain" {
  type = string
  # "XXX.epoch8.co"
  default = null
}

variable "replica_count" {
  type = number
  default = 1
}

variable "resources" {
  type = object({
    cpu    = string
    memory = string
    disk   = string
  })

  default = {
    cpu    = "1"
    memory = "1Gi"
    disk   = "10Gi"
  }
}

######################

locals {
  workload_name_prefix = var.name_prefix != "" ? "${var.name_prefix}-" : ""
  dns_name_prefix = var.name_prefix != "" ? "${var.name_prefix}." : ""
}

resource "random_string" "api_key" {
  count = var.ingress_enabled ? 1 : 0

  length  = 16
  special = false
}

resource "helm_release" "qdrant" {
  name = "${local.workload_name_prefix}qdrant"

  repository = "https://qdrant.github.io/qdrant-helm"
  chart      = "qdrant"
  version    = "0.3.0"

  namespace = var.k8s_namespace

  values = [
    <<EOF
    replicaCount: ${var.replica_count}

    resources:
      requests:
        cpu: 0.1
        memory: ${var.resources.memory}
      limits:
        cpu: ${var.resources.cpu}
        memory: ${var.resources.memory}

    %{ if var.ingress_enabled }
    ingress:
      enabled: true

      annotations:
        kubernetes.io/ingress.class: nginx
        cert-manager.io/cluster-issuer: letsencrypt
        nginx.ingress.kubernetes.io/proxy-body-size: 100m
      
      hosts:
        - host: qdrant.${local.dns_name_prefix}${var.base_domain}
          paths:
            - path: /
              pathType: Prefix
              servicePort: 6333        

      tls:
        - hosts:
            - qdrant.${local.dns_name_prefix}${var.base_domain}
          secretName: ${local.workload_name_prefix}qdrant-tls
    %{ endif }

    persistence:
      size: ${var.resources.disk}

    config:
      %{ if var.replica_count > 1 }
      cluster:
        enabled: true
      %{ endif }
      %{ if var.ingress_enabled }
      service:
        api_key: ${random_string.api_key.0.result}
      %{ endif }

    EOF
  ]
}

output "dns" {
  value = var.ingress_enabled ? "qdrant.${local.dns_name_prefix}${var.base_domain}" : null
}

output "internal_uri" {
  value = "http://${helm_release.qdrant.metadata.0.name}:6333"
}

output "config" {
  value = {
    internal_uri = "http://${helm_release.qdrant.metadata.0.name}:6333"
    external_uri = var.ingress_enabled ? "https://qdrant.${local.dns_name_prefix}${var.base_domain}" : null
    api_key      = var.ingress_enabled ? random_string.api_key.0.result : null
  }
}
