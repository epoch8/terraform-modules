resource "kubernetes_cron_job_v1" "labelstudio_cleaner" {
  count = var.labelstudio_cleaner_enabled ? 1 : 0

  metadata {
    name      = "${var.name}-cleaner"
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

            service_account_name = "${helm_release.labelstudio.metadata.name}-ls-app"

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
