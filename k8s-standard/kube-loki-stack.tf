variable "loki_enabled" {
  type = bool
  default = false
}

variable "kube_loki_stack_version" {
  type = string
  default = "2.10.2"
}

variable "kube_loki_stack_values_override" {
  type = map(any)
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
    templatefile("${path.module}/kube-loki-stack-values.yaml", {}),
    yamlencode(var.kube_loki_stack_values_override)
  ]
}
