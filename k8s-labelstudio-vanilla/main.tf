terraform {
  required_providers {
    helm       = {}
    kubernetes = {}
  }
}

####################

resource "kubernetes_secret_v1" "labelstudio" {
  metadata {
    name      = "${var.project}-labelstudio"
    namespace = var.k8s_namespace
  }

  data = {
    "db_pass" = var.database.password
  }
}

resource "random_string" "labelstudio_admin_password" {
  length  = 10
  special = false
}

resource "random_string" "labelstudio_admin_token" {
  length  = 10
  special = false
}

resource "helm_release" "labelstudio" {
  name = "${var.project}-labelstudio"

  repository = "https://charts.heartex.com/"
  chart      = "label-studio"
  version    = "1.7.1"

  # chart = "${path.module}/../../label-studio-charts/heartex/label-studio"

  # chart   = "oci://ghcr.io/epoch8/label-studio-charts/label-studio/label-studio"
  # version = "1.1.8-rq1"

  namespace = var.k8s_namespace

  values = [
    templatefile(
      "${path.module}/labelstudio-values.yaml",
      {
        db_host = var.database.host
        db_port = var.database.port
        db_name = var.database.dbname
        db_user = var.database.user

        db_pass_secret_name = kubernetes_secret_v1.labelstudio.metadata.0.name
        db_pass_secret_key  = "db_pass"

        ls_admin_username = var.admin_email
        ls_admin_password = random_string.labelstudio_admin_password.result
        ls_admin_token    = random_string.labelstudio_admin_token.result

        ls_domain = "labelstudio.${var.base_domain}"

        app_resources = var.labelstudio_resources

        gcs_persistence = var.labelstudio_gcs_persistence
        s3_persistence  = var.labelstudio_s3_persistence
      }
    )
  ]
}

output "k8s_sa" {
  value = {
    app      = "${var.k8s_namespace}/${helm_release.labelstudio.metadata.0.name}-ls-app",
    rqworker = "${var.k8s_namespace}/${helm_release.labelstudio.metadata.0.name}-ls-rqworker",
  }
}

locals {
  public_uri     = "https://labelstudio.${var.base_domain}"
  internal_uri   = "http://${helm_release.labelstudio.metadata.0.name}-ls-app.${var.k8s_namespace}.svc.cluster.local"
  admin_username = var.admin_email
  admin_password = random_string.labelstudio_admin_password.result
  token          = random_string.labelstudio_admin_token.result
}

output "config" {
  value = {
    db = {
      host     = var.database.host
      port     = var.database.port
      db       = var.database.dbname
      user     = var.database.user
      password = var.database.password
    }
    public_uri     = "https://labelstudio.${var.base_domain}"
    internal_uri   = "http://${helm_release.labelstudio.metadata.0.name}-ls-app.${var.k8s_namespace}.svc.cluster.local"
    admin_username = var.admin_email
    admin_password = random_string.labelstudio_admin_password.result
    token          = random_string.labelstudio_admin_token.result
  }
}
