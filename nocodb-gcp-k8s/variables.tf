variable "name" {
  type = string
}

variable "gcp_sql_database_instance" {
  type = string
}

variable "k8s_namespace" {
  type = string
}

variable "base_domain" {
  type = string
}

variable "admin_email" {
  default = "admin@epoch8.co"
}

variable "nocodb_version" {
  default = "0.111.4"
}

locals {
  name_with_underlines = replace(var.name, "-", "_")
}
