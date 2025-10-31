terraform {
  required_providers {
    authentik = {
      source  = "goauthentik/authentik"
      version = ">=2025.6.0"
    }
  }
}

###

variable "project" {
  type        = string
  description = "The name of the project this app belongs to, used to display in Authentik"
}

variable "app_slug" {
  type        = string
  description = "The slug of the application in Authentik"
}

variable "app_name" {
  type        = string
  description = "The name of the application in Authentik"
}

variable "app_domain" {
  type        = string
  description = "The domain of the application"
}

variable "authentik_host" {
  type    = string
  default = "https://authentik.chatbot.epoch8.co"
}

variable "authentik_group_ids" {
  type    = list(string)
  default = []
}

variable "authentik_service_connection_kubernetes_name" {
  type    = string
  default = "Local Kubernetes Cluster"
}

variable "authentik_authorization_flow_slug" {
  type    = string
  default = "default-provider-authorization-implicit-consent"
}

variable "authentik_invalidation_flow_slug" {
  type    = string
  default = "default-provider-invalidation-flow"
}

variable "skip_path_regex" {
  type    = string
  default = null
}

###

data "authentik_flow" "default_authorization_flow" {
  slug = var.authentik_authorization_flow_slug
}

data "authentik_flow" "default_invalidation_flow" {
  slug = var.authentik_invalidation_flow_slug
}

resource "authentik_provider_proxy" "project" {
  name = "${var.app_slug}-proxy"

  mode = "forward_single"

  external_host = "https://${var.app_domain}"

  access_token_validity = "hours=3"

  skip_path_regex = var.skip_path_regex

  authorization_flow = data.authentik_flow.default_authorization_flow.id
  invalidation_flow  = data.authentik_flow.default_invalidation_flow.id
}

resource "authentik_application" "project" {
  name = var.app_name
  slug = var.app_slug

  group = var.project

  protocol_provider = authentik_provider_proxy.project.id
}

resource "authentik_policy_binding" "project_groups" {
  for_each = toset(var.authentik_group_ids)

  target = authentik_application.project.uuid
  group  = each.value
  order  = 0
}

data "authentik_service_connection_kubernetes" "default" {
  name = var.authentik_service_connection_kubernetes_name
}

resource "authentik_outpost" "project" {
  name = var.app_slug

  type = "proxy"

  service_connection = data.authentik_service_connection_kubernetes.default.id

  protocol_providers = [
    authentik_provider_proxy.project.id
  ]

  config = jsonencode({
    authentik_host                = var.authentik_host
    kubernetes_namespace          = "authentik"
    kubernetes_ingress_class_name = "nginx"
    kubernetes_ingress_annotations = {
      "cert-manager.io/cluster-issuer" = "letsencrypt"
    }
    kubernetes_ingress_secret_name = "${var.app_slug}-outpost-tls"
  })
}

output "ingress_annotations" {
  value = {
    "nginx.ingress.kubernetes.io/auth-signin"           = "https://${var.app_domain}/outpost.goauthentik.io/start?rd=$scheme://$http_host$escaped_request_uri"
    "nginx.ingress.kubernetes.io/auth-url"              = "http://ak-outpost-${authentik_outpost.project.name}.authentik.svc.cluster.local:9000/outpost.goauthentik.io/auth/nginx"
    "nginx.ingress.kubernetes.io/auth-response-headers" = "Set-Cookie,X-authentik-username,X-authentik-groups,X-authentik-entitlements,X-authentik-email,X-authentik-name,X-authentik-uid"
    "nginx.ingress.kubernetes.io/auth-snippet"          = "proxy_set_header X-Forwarded-Host $http_host;"
  }
}
