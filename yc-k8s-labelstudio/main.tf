terraform {
  required_providers {
    helm       = {}
    kubernetes = {}
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
}

variable "project" {
  type = string
}

variable "k8s_namespace" {
  type = string
}

variable "labelstudio_resources" {
  type = object({
    requests = object({
      cpu    = string
      memory = string
    })
    limits = object({
      cpu    = string
      memory = string
    })
  })

  default = {
    requests = {
      cpu    = "100m"
      memory = "512m"
    }
    limits = {
      cpu    = "1"
      memory = "1Gi"
    }
  }
}

variable "yc_mdb_postgresql_cluster" {
  default = null

  type = object({
    id   = string
    fqdn = string
  })
}

# variable "yc_s3_root_key" {
#   type = object({
#     access_key = string
#     secret_key = string
#   })
# }

variable "admin_email" {
  type    = string
  default = "admin@epoch8.co"
}

variable "base_domain" {
  type = string
  # "XXX.epoch8.co"
}

locals {
  project_with_underlines = replace(var.project, "-", "_")
}

resource "random_string" "labelstudio_password" {
  length  = 16
  special = false
}

resource "yandex_mdb_postgresql_user" "labelstudio_user" {
  cluster_id = var.yc_mdb_postgresql_cluster.id

  name       = "${local.project_with_underlines}_labelstudio"
  password   = random_string.labelstudio_password.result
  conn_limit = 10
}

resource "yandex_mdb_postgresql_database" "labelstudio_db" {
  cluster_id = var.yc_mdb_postgresql_cluster.id

  name  = "${local.project_with_underlines}_labelstudio"
  owner = yandex_mdb_postgresql_user.labelstudio_user.name

  extension {
    name = "pg_trgm"
  }

  extension {
    name = "btree_gin"
  }
}

resource "random_string" "labelstudio_admin_user_password" {
  length  = 16
  special = false
}

resource "kubernetes_secret_v1" "labelstudio" {
  metadata {
    name      = "${var.project}-labelstudio"
    namespace = var.k8s_namespace
  }

  data = {
    "db_pass" = yandex_mdb_postgresql_user.labelstudio_user.password
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

  # repository = "https://charts.heartex.com/"
  # chart      = "label-studio"
  # version    = "1.1.4"

  # chart = "${path.module}/../../label-studio-charts/heartex/label-studio"

  chart   = "oci://ghcr.io/epoch8/label-studio-charts/label-studio/label-studio"
  version = "1.1.8-rq0"

  namespace = var.k8s_namespace

  values = [
    templatefile(
      "${path.module}/labelstudio-values.yaml",
      {
        db_host = var.yc_mdb_postgresql_cluster.fqdn
        db_port = 6432
        db_name = yandex_mdb_postgresql_database.labelstudio_db.name
        db_user = yandex_mdb_postgresql_user.labelstudio_user.name

        db_pass_secret_name = kubernetes_secret_v1.labelstudio.metadata.0.name
        db_pass_secret_key  = "db_pass"

        ls_admin_username = var.admin_email
        ls_admin_password = random_string.labelstudio_admin_password.result
        ls_admin_token    = random_string.labelstudio_admin_token.result

        ls_domain = "labelstudio.${var.base_domain}"

        app_resources = var.labelstudio_resources
      }
    )
  ]
}

output "config" {
  value = {
    db = {
      host     = var.yc_mdb_postgresql_cluster.fqdn
      port     = 6432
      db       = yandex_mdb_postgresql_database.labelstudio_db.name
      user     = yandex_mdb_postgresql_user.labelstudio_user.name
      password = random_string.labelstudio_password.result
    }
    public_uri     = "https://labelstudio.${var.base_domain}"
    internal_uri   = "http://${helm_release.labelstudio.metadata.0.name}-ls-app.${var.k8s_namespace}.svc.cluster.local"
    admin_username = var.admin_email
    admin_password = random_string.labelstudio_admin_password.result
    token          = random_string.labelstudio_admin_token.result
  }
}
