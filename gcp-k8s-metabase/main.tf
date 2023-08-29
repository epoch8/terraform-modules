variable "gcp_project" {
  description = "Name of the GCP project"
  type        = string
}

variable "base_domain" {
  description = "Base domain for the service"
  type        = string
}

variable "metabase_k8s_namespace" {
  description = "K8s namespace for metabase helm chart"
  type        = string
  default     = "default"
}

variable "metabase_db_instance" {}

variable "metabase_db_user" {
  description = "Name of user in 'metadata' DB instance for metabase"
  type        = string
  default     = "metabase"
}

variable "metabase_db_dbname" {
  description = "Name of database in 'metadata' DB instance for metabase"
  type        = string
  default     = "metabase"
}

# variable "metabase_db_password" {
#   description = "Password for user 'metabase' in 'metadata' DB"
#   type = string
# }

data "google_sql_database_instance" "db" {
  name = var.metabase_db_instance

  project = var.gcp_project
}

locals {
  db_ip = data.google_sql_database_instance.db.ip_address.0.ip_address
}

resource "google_sql_database" "metabase" {
  name = var.metabase_db_dbname

  project  = var.gcp_project
  instance = var.metabase_db_instance
}

resource "random_string" "metabase_db_password" {
  length  = 16
  special = false

  lifecycle {
    ignore_changes = [
      special
    ]
  }
}

resource "google_sql_user" "metabase" {
  name = var.metabase_db_user

  project  = var.gcp_project
  instance = var.metabase_db_instance

  password = random_string.metabase_db_password.result
}

output "metabase_db_conn_url" {
  value = "postgres://${google_sql_user.metabase.name}:${random_string.metabase_db_password.result}@${local.db_ip}:5432/${google_sql_database.metabase.name}"
}

resource "kubernetes_manifest" "metabase-managed-cert" {
  manifest = {
    "apiVersion" = "networking.gke.io/v1"
    "kind"       = "ManagedCertificate"
    "metadata" = {
      "name"      = "metabase-managed-certificate"
      "namespace" = var.metabase_k8s_namespace
    }
    "spec" = {
      "domains" = ["metabase.${var.base_domain}"]
    }
  }
}

resource "helm_release" "metabase" {
  name = "metabase"

  repository = "https://epoch8.github.io/helm-charts/"
  # repository = "../../../helm-charts/charts"
  chart      = "metabase"
  version    = "0.14.4"

  namespace = var.metabase_k8s_namespace

  values = [
    templatefile(
      "${path.module}/metabase-values.yaml",
      {
        ingress_host = "metabase.${var.base_domain}"

        db_host     = local.db_ip
        db_dbname   = google_sql_database.metabase.name
        db_username = google_sql_user.metabase.name
        db_password = random_string.metabase_db_password.result
      }
    )
  ]
}

data "kubernetes_ingress_v1" "metabase" {
  metadata {
    name      = helm_release.metabase.name
    namespace = var.metabase_k8s_namespace
  }
  depends_on = [
    helm_release.metabase
  ]
}

output "metabase_ingress_ip" {
  value = data.kubernetes_ingress_v1.metabase.status.0.load_balancer.0.ingress.0.ip
}
