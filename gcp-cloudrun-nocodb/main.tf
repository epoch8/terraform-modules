variable "slug" {
  type = string
  default = ""
}

variable "gcp_project_name" {
  type = string
}

variable "gcp_location" {
  type = string
}

variable "google_sql_database_instance_name" {
  type = string
}

variable "gcp_dns_zone" {
  type    = string
  default = "epoch8-dev"
}

variable "admin_email" {
  type = string
  default = "admin@epoch8.co"
}

####################

locals {
  slug_dash = var.slug != "" ? "${var.slug}-" : ""
  slug_dot = var.slug != "" ? "${var.slug}." : ""
}

####################


data "google_sql_database_instance" "db" {
  name = var.google_sql_database_instance_name
}

resource "google_service_account" "default" {
  account_id = "${local.slug_dash}nocodb"
}

resource "random_string" "nocodb_db_password" {
  length  = 15
  special = false
}

resource "google_sql_user" "nocodb" {
  name = "nocodb"

  instance = var.google_sql_database_instance_name
  password = random_string.nocodb_db_password.result
}

resource "google_sql_database" "nocodb" {
  name     = "nocodb"
  instance = var.google_sql_database_instance_name
}

resource "random_string" "nocodb_admin_password" {
  length  = 15
  special = false
}

resource "random_string" "nocodb_jwt_secret" {
  length  = 15
  special = false
}

resource "google_cloud_run_v2_service" "nocodb" {
  name     = "${local.slug_dash}nocodb"
  location = var.gcp_location
  ingress  = "INGRESS_TRAFFIC_ALL"
  project  = var.gcp_project_name

  template {
    service_account = google_service_account.default.email

    scaling {
      max_instance_count = 3
    }

    containers {
      image = "nocodb/nocodb:0.202.9"

      env {
        name  = "NC_DB"
        value = "pg://${data.google_sql_database_instance.db.public_ip_address}:5432?u=${google_sql_user.nocodb.name}&p=${random_string.nocodb_db_password.result}&d=${google_sql_database.nocodb.name}"
      }

      env {
        name  = "NC_AUTH_JWT_SECRET"
        value = random_string.nocodb_jwt_secret.result
      }

      env {
        name  = "NC_ADMIN_EMAIL"
        value = var.admin_email
      }

      env {
        name  = "NC_ADMIN_PASSWORD"
        value = random_string.nocodb_admin_password.result
      }

      ports {
        container_port = 8080
      }

      resources {
        limits = {
          cpu    = "1000m"
          memory = "512Mi"
        }

        cpu_idle = true
      }

      startup_probe {
        http_get {
          path = "/api/v1/health"
        }
      }
    }
  }

  lifecycle {
    ignore_changes = [
      annotations,
    ]
  }
}

resource "google_cloud_run_domain_mapping" "default" {
  location = var.gcp_location
  name     = "nocodb.${local.slug_dot}${trimsuffix(data.google_dns_managed_zone.default.dns_name, ".")}"

  metadata {
    namespace = var.gcp_project_name
  }

  spec {
    route_name = google_cloud_run_v2_service.nocodb.name
  }
}

data "google_dns_managed_zone" "default" {
  name = var.gcp_dns_zone
}

resource "google_dns_record_set" "default" {
  name         = "nocodb.${local.slug_dot}${data.google_dns_managed_zone.default.dns_name}"
  managed_zone = data.google_dns_managed_zone.default.name
  type         = google_cloud_run_domain_mapping.default.status[0].resource_records[0].type
  ttl          = 300

  rrdatas = [google_cloud_run_domain_mapping.default.status[0].resource_records[0].rrdata]
}

output "config" {
  value = {
    uri      = "http://nocodb.${local.slug_dot}${trimsuffix(data.google_dns_managed_zone.default.dns_name, ".")}"
    user     = var.admin_email
    password = random_string.nocodb_admin_password.result
  }
}
