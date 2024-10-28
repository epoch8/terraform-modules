variable "project" {
  type = string
}

variable "k8s_namespace" {
  type = string
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
