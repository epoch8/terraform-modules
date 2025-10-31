resource "random_password" "memgraph_password" {
  length  = 16
  special = false
}

module "memgraph" {
  source = "git@github.com:epoch8/terraform-modules.git//k8s-memgraph?ref=add_vedana_app_module"

  kubernetes_namespace = var.k8s_namespace
  name                 = "${local.slug}-memgraph"
  user                 = var.project
  password             = random_password.memgraph_password.result
  resources            = var.memgraph_resources
}
