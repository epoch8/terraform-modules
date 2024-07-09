terraform {
  required_providers {
    helm = {}
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
}

################

variable "yc_mdb_postgresql_cluster" {
  default = null

  type = object({
    id = string
    fqdn = string
  })
}

variable "k8s_namespace" {
  type = string
  default = "default"
}

variable "name" {
  type = string
}

locals {
  name_with_underlines = replace(var.name, "-", "_")
}

################

data "yandex_mdb_postgresql_cluster" "db" {
  cluster_id = var.yc_mdb_postgresql_cluster.id
}

resource "random_string" "mb_password" {
  length  = 16
  special = false
}

resource "yandex_mdb_postgresql_user" "mb_user" {
  cluster_id = var.yc_mdb_postgresql_cluster.id

  name       = "${local.name_with_underlines}_metabase"
  password   = random_string.mb_password.result
  conn_limit = 20 # У метабейза захардкожен connection pool size=15 и мы хотим иметь возможность делать туда запросы
}

resource "yandex_mdb_postgresql_database" "mb_db" {
  cluster_id = var.yc_mdb_postgresql_cluster.id

  name  = "${local.name_with_underlines}_metabase"
  owner = yandex_mdb_postgresql_user.mb_user.name

  extension {
    name = "citext"
  }
}

resource "helm_release" "metabase" {
  name = "${var.name}-metabase"

  repository = "https://epoch8.github.io/helm-charts/"
  chart      = "metabase"
  version    = "0.14.2"

  namespace = var.k8s_namespace

  values = [
    templatefile(
      "${path.module}/yc-shared-metabase-values.yaml",
      {
        ingress_host = "metabase.${var.name}.epoch8.co"

        db_host     = data.yandex_mdb_postgresql_cluster.db.host.0.fqdn
        db_port     = 6432
        db_dbname   = yandex_mdb_postgresql_database.mb_db.name
        db_username = yandex_mdb_postgresql_user.mb_user.name
        db_password = random_string.mb_password.result
      }
    )
  ]
}

# module "metabase_dns" {
#   source = "../../modules/e8-dns-entry"

#   dns_name = "metabase.${var.name}"
#   type     = "CNAME"
#   records = [
#     "ingress-yc.epoch8.co"
#   ]
# }

output "config"{
  value = {
    metabase_url = "https://metabase.${var.name}.epoch8.co/"
    metabase_db  = "postgres://${local.name_with_underlines}_metabase:${random_string.mb_password.result}@${data.yandex_mdb_postgresql_cluster.db.host.0.fqdn}:6432/${local.name_with_underlines}_metabase"
  }
}
