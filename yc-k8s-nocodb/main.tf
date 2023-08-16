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

# Use SQLite instead of PostgreSQL. If set to true, the following variables 
# are ignored: yc_mdb_postgresql_cluster.
variable "noco_use_sqlite" {
  description = "Use SQLite instead of PostgreSQL"

  default = false
}

variable "yc_mdb_postgresql_cluster" {
  default = null

  type = object({
    id = string
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
  default = "admin@epoch8.co"
}

locals {
  project_with_underlines = replace(var.project, "-", "_")
}

resource "random_string" "nocodb_password" {
  count = var.noco_use_sqlite ? 0 : 1

  length  = 16
  special = false
}

resource "yandex_mdb_postgresql_user" "nocodb_user" {
  count = var.noco_use_sqlite ? 0 : 1

  cluster_id = var.yc_mdb_postgresql_cluster.id

  name       = "${local.project_with_underlines}_nocodb"
  password   = random_string.nocodb_password.0.result
  conn_limit = 10
}

resource "yandex_mdb_postgresql_database" "nocodb_db" {
  count = var.noco_use_sqlite ? 0 : 1

  cluster_id = var.yc_mdb_postgresql_cluster.id

  name  = "${local.project_with_underlines}_nocodb"
  owner = yandex_mdb_postgresql_user.nocodb_user.0.name
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
  access_key = var.yc_s3_root_key.access_key
  secret_key = var.yc_s3_root_key.secret_key
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
  version    = "0.10.2"

  namespace = var.k8s_namespace

  values = [
    templatefile(
      "${path.module}/nocodb-values.yaml",
      {
        ingress_host = "nocodb.${var.project}.epoch8.co"

        name = "${var.project}-nocodb"

        use_sqlite = var.noco_use_sqlite

        db_host     = var.yc_mdb_postgresql_cluster.fqdn
        db_port     = 6432
        db_dbname   = var.noco_use_sqlite ? "" : yandex_mdb_postgresql_database.nocodb_db.0.name
        db_username = var.noco_use_sqlite ? "" : yandex_mdb_postgresql_user.nocodb_user.0.name
        db_password = var.noco_use_sqlite ? "" : random_string.nocodb_password.0.result

        admin_email    = var.admin_email
        admin_password = random_string.nocodb_admin_user_password.result
      }
    )
  ]
}

output "config" {
  value = {
    nocodb_url = "https://nocodb.${var.project}.epoch8.co/"

    nocodb_db = var.noco_use_sqlite ? "local sqlite" : "postgres://${yandex_mdb_postgresql_user.nocodb_user.0.name}:${random_string.nocodb_password.0.result}@${var.yc_mdb_postgresql_cluster.fqdn}:6432/${yandex_mdb_postgresql_database.nocodb_db.0.name}"

    admin_email    = var.admin_email
    admin_password = random_string.nocodb_admin_user_password.result

    s3_bucket     = yandex_storage_bucket.media.bucket
    s3_access_key = yandex_iam_service_account_static_access_key.nocodb_key.access_key
    s3_secret_key = nonsensitive(yandex_iam_service_account_static_access_key.nocodb_key.secret_key)
  }
}
