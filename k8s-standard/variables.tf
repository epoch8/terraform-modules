variable "google_dns_managed_zone" {
  type = object({
    name     = string
    dns_name = string
  })
}

variable "admin_email" {
  type    = string
  default = "admin@epoch8.co"
}

variable "kp_namespace" {
  type    = string
  default = "kube-prometheus-stack"
}

variable "loki_enabled" {
  type = bool
  default = false
}

variable "nginx_resources" {
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
      memory = "128Mi"
    }
    limits = {
      cpu    = "250m"
      memory = "256Mi"
    }
  }
}
