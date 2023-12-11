variable "slug" {}
variable "gcp_project_name" {}
variable "gcp_location" {}
variable "google_sql_database_instance_name" {}
variable "google_sql_database_instance_ip_address" {}

resource "google_service_account" "default" {
  account_id = "${var.slug}-nocodb"
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
  name     = "${var.slug}-nocodb"
  location = var.gcp_location
  ingress  = "INGRESS_TRAFFIC_ALL"
  project  = var.gcp_project_name

  template {
    service_account = google_service_account.default.email

    scaling {
      max_instance_count = 3
    }

    containers {
      image = "nocodb/nocodb:0.105.3"

      env {
        name  = "NC_DB"
        value = "pg://${var.google_sql_database_instance_ip_address}:5432?u=${google_sql_user.nocodb.name}&p=${random_string.nocodb_db_password.result}&d=${google_sql_database.nocodb.name}"
      }

      env {
        name  = "NC_AUTH_JWT_SECRET"
        value = random_string.nocodb_jwt_secret.result
      }

      env {
        name  = "NC_ADMIN_EMAIL"
        value = "admin@epoch8.co"
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
  name     = "nocodb.${var.slug}.${trimsuffix(data.google_dns_managed_zone.epoch8_dev.dns_name, ".")}"

  metadata {
    namespace = var.gcp_project_name
  }

  spec {
    route_name = google_cloud_run_v2_service.nocodb.name
  }
}

data "google_dns_managed_zone" "epoch8_dev" {
  name = "epoch8-dev"
}

resource "google_dns_record_set" "default" {
  name         = "nocodb.${var.slug}.${data.google_dns_managed_zone.epoch8_dev.dns_name}"
  managed_zone = data.google_dns_managed_zone.epoch8_dev.name
  type         = google_cloud_run_domain_mapping.default.status[0].resource_records[0].type
  ttl          = 300

  rrdatas = [google_cloud_run_domain_mapping.default.status[0].resource_records[0].rrdata]
}

output "config" {
  value = {
    uri      = "http://nocodb.${var.slug}.${trimsuffix(data.google_dns_managed_zone.epoch8_dev.dns_name, ".")}"
    user     = "admin@epoch8.co"
    password = random_string.nocodb_admin_password.result
  }
}
