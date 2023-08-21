terraform {
  required_providers {
    helm = {}
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


variable "yc_mdb_postgresql_cluster" {
  default = null

  type = object({
    id = string
    fqdn = string
  })
}

locals {
  project_with_underlines = replace(var.project, "-", "_")
}

resource "random_string" "metabase_password" {
  length  = 16
  special = false
}

resource "yandex_mdb_postgresql_user" "metabase_user" {

  cluster_id = var.yc_mdb_postgresql_cluster.id

  name       = "${local.project_with_underlines}_metabase"
  password   = random_string.metabase_password.0.result
  conn_limit = 10
}

resource "yandex_mdb_postgresql_database" "metabase_db" {
  cluster_id = var.yc_mdb_postgresql_cluster.id

  name  = "${local.project_with_underlines}_metabase"
  owner = yandex_mdb_postgresql_user.metabase_user.0.name
}


resource "helm_release" "metabase" {
  name = "${var.project}-metabase"

  repository = "https://epoch8.github.io/helm-charts/"
  chart      = "simple-app"
  version    = "0.10.2"

  namespace = var.k8s_namespace

  values = [
    templatefile(
      "${path.module}/metabase-values.yaml",
      {
        ingress_host = "metabase.${var.project}.epoch8.co"

        name = "${var.project}-metabase"
        db_host     = var.yc_mdb_postgresql_cluster.fqdn
        db_port     = 6432
        db_dbname   = yandex_mdb_postgresql_database.metabase_db.0.name
        db_username = yandex_mdb_postgresql_user.metabase_user.0.name
        db_password = random_string.metabase_password.0.result
      }
    )
  ]
}

output "config" {
  value = {
    metabase_url = "https://metabase.${var.project}.epoch8.co/"

    metabase_db = "postgres://${yandex_mdb_postgresql_user.metabase_user.0.name}:${random_string.metabase_password.0.result}@${var.yc_mdb_postgresql_cluster.fqdn}:6432/${yandex_mdb_postgresql_database.metabase_db.0.name}"


  }
}
