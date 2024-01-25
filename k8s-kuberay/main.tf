variable "k8s_kuberay_namespace" {
  description = "Namespace to deploy to"
  type        = string
  default     = "kuberay"
}

# create namespace
resource "kubernetes_namespace" "kuberay" {
  metadata {
    name = var.k8s_kuberay_namespace
  }
}

# deploy kuberay operator
resource "helm_release" "kuberay" {
  name       = "kuberay"
  repository = "https://ray-project.github.io/kuberay-helm/"
  chart      = "kuberay-operator"
  namespace  = kubernetes_namespace.kuberay.metadata[0].name
  version    = "1.0.0"
  values = [
    jsonencode({
    })
  ]
}
