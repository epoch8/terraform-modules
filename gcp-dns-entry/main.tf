locals {
  ingress_base_domain = replace(var.dns_name, "/\\.$/", "")
  ingress_domain      = "ingress-nginx.${local.ingress_base_domain}"
}

resource "google_dns_record_set" "ingress_nginx" {
  name = "${local.ingress_domain}."
  type = "A"
  ttl  = 300

  managed_zone = var.managed_zone_name

  rrdatas = [
    var.ingress_ip
  ]
}

resource "google_dns_record_set" "all_subdomains" {
  name = "*.${local.ingress_base_domain}."
  type = "CNAME"
  ttl  = 300

  managed_zone = var.managed_zone_name

  rrdatas = [
    google_dns_record_set.ingress_nginx.name
  ]
}

output "ingress_dns" {
  value = google_dns_record_set.ingress_nginx.name
}