# Модули

## k8s-standard

* Настраивает ingress-nginx, cert-manager
* Прописывает DNS ingress-nginx.XXX.epoch8.dev

### Requirements

Providers:

* `google`
* `kubernetes`
* `helm`

### Setup

Сначала нужно создать helm-релиз для cert_manager

1. `terraform apply -target module.yc_k8s_standard.helm_release.cert_manager`
1. `terraform apply`