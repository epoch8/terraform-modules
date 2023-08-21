variable "labelstudio_cleaner_enabled" {
  type = bool

  default = false
}

variable "labelstudio_cleaner_retention_days" {
  type = number

  default = 7
}

resource "kubernetes_cron_job_v1" "labelstudio_cleaner" {
  metadata {
    name      = "${var.project}-labelstudio-cleaner"
    namespace = var.k8s_namespace
  }

  spec {
    schedule           = "0 * * * *"
    concurrency_policy = "Forbid"
    suspend            = var.labelstudio_cleaner_enabled ? false : true

    job_template {
      metadata {}
      spec {
        template {
          metadata {}
          spec {
            restart_policy = "OnFailure"

            service_account_name = "${helm_release.labelstudio.metadata.0.name}-ls-app"

            container {
              name  = "labelstudio-cleaner"
              image = "ghcr.io/epoch8/ls-cleaner/ls-cleaner:0.1.1"
              env {
                name  = "LS_URL"
                value = local.internal_uri
              }
              env {
                name  = "LS_API_KEY"
                value = local.token
              }
              env {
                name  = "RETENTION_DAYS"
                value = var.labelstudio_cleaner_retention_days
              }
              resources {
                requests = {
                  cpu    = 0.25
                  memory = "1Gi"
                }
                limits = {
                  cpu    = 1
                  memory = "2Gi"
                }
              }
            }
          }
        }
      }
    }
  }
}
