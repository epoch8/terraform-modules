variable "project" {
  type = string
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "sentry_dsn" {
  type    = string
  default = null
}

variable "k8s_namespace" {
  type = string
}

variable "base_domain" {
  type = string
}

variable "yc_mdb_cluster_id" {
  type = string
}

variable "memgraph_resources" {
  type = object({
    requests : map(string)
    limits : map(string)
  })
  default = {
    requests = { cpu = "0.1", memory = "2Gi" }
    limits   = { cpu = "1", memory = "3Gi" }
  }
}

variable "image_repository" {
  type    = string
}

variable "image_tag" {
  type    = string
}

variable "image_pull_secrets" {
  type    = string
  default = null
}

variable "telegram_bot_token" {
  type    = string
  default = null
}

variable "grist" {
  type = object({
    server_url = string
    api_key    = string

    data_model_doc_id = string
    data_doc_id       = string
    test_set_doc_id   = optional(string)
  })
}

variable "llm_config" {
  type = object({
    openai_base_url  = optional(string)
    openai_api_key   = optional(string)
    gcp_sa_json      = optional(string)
    model            = optional(string)
    embeddings_model = optional(string)
    embeddings_dim   = optional(string)
  })
}

###

variable "enable_api" {
  type    = bool
  default = false
}

variable "api_command" {
  type    = list(string)
  default = null
}

variable "api_resources" {
  type = object({
    requests = map(string)
    limits   = map(string)
  })
  default = {
    requests = { cpu = "200m", memory = "512Mi" }
    limits   = { cpu = "500m", memory = "1Gi" }
  }
}

###

variable "authentik_group_ids" {
  type    = list(string)
  default = []
}

variable "gdrive_config" {
  type = object({
    folder_id   = string
    gcp_sa_json = string
  })
  default = null
}

variable "apply_pii_masking" {
  type    = bool
  default = false
}