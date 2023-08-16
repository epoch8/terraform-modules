terraform {
  required_providers {
    helm = {}
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
}

variable "project" {
}

variable "k8s_namespace" {
}

variable "yc_mdb_postgresql_cluster_id" {
}

variable "yc_mdb_postgresql_cluster_fqdn" {
}

variable "yc_s3_root_access_key" {
}

variable "yc_s3_root_secret_key" {
}

variable "admin_email" {
  default = "admin@epoch8.co"
}

resource "random_string" "nocodb_password" {
  length  = 16
  special = false
}

resource "yandex_mdb_postgresql_user" "nocodb_user" {
  cluster_id = var.yc_mdb_postgresql_cluster_id

  name       = "${var.project}_nocodb"
  password   = random_string.nocodb_password.result
  conn_limit = 10
}

resource "yandex_mdb_postgresql_database" "nocodb_db" {
  cluster_id = var.yc_mdb_postgresql_cluster_id

  name  = "${var.project}_nocodb"
  owner = yandex_mdb_postgresql_user.nocodb_user.name
}

resource "random_string" "nocodb_admin_user_password" {
  length  = 16
  special = false
}

resource "yandex_iam_service_account" "nocodb" {
  name = "${var.project}-nocodb"
}

# Create service account key
resource "yandex_iam_service_account_static_access_key" "nocodb_key" {
  service_account_id = yandex_iam_service_account.nocodb.id
}

resource "yandex_storage_bucket" "media" {
  access_key = var.yc_s3_root_access_key
  secret_key = var.yc_s3_root_secret_key
  bucket     = "${var.project}-nocodb-media"

  grant {
    id          = yandex_iam_service_account.nocodb.id
    type        = "CanonicalUser"
    permissions = ["FULL_CONTROL"]
  }

  grant {
    uri         = "http://acs.amazonaws.com/groups/global/AllUsers"
    type        = "Group"
    permissions = ["READ"]
  }
}

resource "helm_release" "nocodb" {
  name = "${var.project}-nocodb"

  repository = "https://epoch8.github.io/helm-charts/"
  chart      = "simple-app"
  version    = "0.6.0"

  namespace = var.k8s_namespace

  values = [
    templatefile(
      "${path.module}/yc-nocodb-values.yaml",
      {
        ingress_host = "nocodb.${var.project}.epoch8.co"

        name = "${var.project}-nocodb"

        db_host     = var.yc_mdb_postgresql_cluster_fqdn
        db_port     = 6432
        db_dbname   = yandex_mdb_postgresql_database.nocodb_db.name
        db_username = yandex_mdb_postgresql_user.nocodb_user.name
        db_password = random_string.nocodb_password.result

        admin_email    = var.admin_email
        admin_password = random_string.nocodb_admin_user_password.result
      }
    )
  ]
}

output "config" {
  value = {
    nocodb_url = "https://nocodb.${var.project}.epoch8.co/"

    nocodb_db = "postgres://${yandex_mdb_postgresql_user.nocodb_user.name}:${random_string.nocodb_password.result}@${var.yc_mdb_postgresql_cluster_fqdn}:6432/${yandex_mdb_postgresql_database.nocodb_db.name}"

    admin_email    = var.admin_email
    admin_password = random_string.nocodb_admin_user_password.result

    s3_bucket     = yandex_storage_bucket.media.bucket
    s3_access_key = yandex_iam_service_account_static_access_key.nocodb_key.access_key
    s3_secret_key = nonsensitive(yandex_iam_service_account_static_access_key.nocodb_key.secret_key)
  }
}
