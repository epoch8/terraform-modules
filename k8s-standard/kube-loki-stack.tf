variable "loki_enabled" {
  type = bool
  default = false
}

variable "loki_disk_size_gb" {
  default = 50
}

variable "loki_retention_days" {
  default = 7
}

variable "kube_loki_stack_version" {
  type = string
  default = "2.10.3"
}

variable "kube_loki_stack_values_override" {
  type = any
  default = {}
}

resource "kubernetes_namespace" "kube-loki-stack" {
  count = var.loki_enabled ? 1 : 0
  metadata {
    name = "kube-loki-stack"
  }
}

resource "helm_release" "kube_loki_stack" {
  name = "kube-loki-stack"
  count = var.loki_enabled ? 1 : 0

  repository = "https://grafana.github.io/helm-charts"
  chart      = "loki-stack"
  version    = var.kube_loki_stack_version

  namespace = kubernetes_namespace.kube-loki-stack[0].metadata.0.name

  values = [
    <<EOF
    loki:
      enabled: true

      config:
        table_manager:
          retention_deletes_enabled: true
          retention_period: ${var.loki_retention_days}d

      persistence:
        enabled: true
        size: ${var.loki_disk_size_gb}Gi

      resources:
        requests:
          cpu: 100m
          memory: 750Mi
        limits:
          cpu: 1
          memory: 1Gi
    EOF
    ,
    yamlencode(var.kube_loki_stack_values_override)
  ]
}
