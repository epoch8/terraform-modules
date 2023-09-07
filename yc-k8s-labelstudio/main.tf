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

module "labelstudio" {
  source = "../k8s-labelstudio"

  project               = var.project
  k8s_namespace         = var.k8s_namespace
  labelstudio_resources = var.labelstudio_resources
  base_domain           = var.base_domain

  database = {
    host     = var.yc_mdb_postgresql_cluster.fqdn
    port     = 6432
    dbname   = yandex_mdb_postgresql_database.labelstudio_db.name
    user     = yandex_mdb_postgresql_user.labelstudio_user.name
    password = random_string.labelstudio_password.result
  }
}


output "config" {
  value = module.labelstudio.config
}
