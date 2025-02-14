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

variable "yc_s3_root_key" {
  type = object({
    access_key = string
    secret_key = string
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

####################

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

resource "yandex_iam_service_account" "labelstudio" {
  name = "${var.project}-labelstudio"
}

# Create service account key
resource "yandex_iam_service_account_static_access_key" "labelstudio_key" {
  service_account_id = yandex_iam_service_account.labelstudio.id
}

resource "yandex_storage_bucket" "media" {
  access_key = var.yc_s3_root_key.access_key
  secret_key = var.yc_s3_root_key.secret_key
  bucket     = "${var.project}-labelstudio-media"

  grant {
    id          = yandex_iam_service_account.labelstudio.id
    type        = "CanonicalUser"
    permissions = ["FULL_CONTROL"]
  }

  # grant {
  #   uri         = "http://acs.amazonaws.com/groups/global/AllUsers"
  #   type        = "Group"
  #   permissions = ["READ"]
  # }
}

module "labelstudio" {
  source = "../k8s-labelstudio-vanilla"

  name = "${var.project}-labelstudio"

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

  labelstudio_s3_persistence = {
    access_key = yandex_iam_service_account_static_access_key.labelstudio_key.access_key
    secret_key = yandex_iam_service_account_static_access_key.labelstudio_key.secret_key

    bucket = yandex_storage_bucket.media.bucket
    region = "ru-central1"
    prefix = ""
    endpoint = "https://storage.yandexcloud.net"
  }
}


output "config" {
  value = module.labelstudio.config
}
