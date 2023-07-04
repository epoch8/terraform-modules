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
  version    = "2.9.9"

  namespace = kubernetes_namespace.kube-loki-stack.metadata.0.name

  values = [
    templatefile("${path.module}/kube-loki-stack-values.yaml", {})
  ]
}
