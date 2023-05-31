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
