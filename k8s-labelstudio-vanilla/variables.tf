variable "project" {
  type = string
}

variable "k8s_namespace" {
  type = string
}

variable "database" {
  type = object({
    host     = string
    port     = number
    dbname   = string
    user     = string
    password = string
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

variable "labelstudio_gcs_persistence" {
  default = null
  type = object({
    project                      = string
    bucket                       = string
    prefix                       = string
    application_credentials_json = string
  })
}

variable "labelstudio_s3_persistence" {
  default = null
  type = object({
    access_key = string
    secret_key = string
    region     = string
    bucket     = string
    prefix     = string
    endpoint   = string
  })
}

variable "labelstudio_cleaner_enabled" {
  type = bool

  default = false
}

variable "labelstudio_cleaner_retention_days" {
  type = number

  default = 7
}

