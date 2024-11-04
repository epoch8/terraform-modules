# Модуль `k8s-standard`

* Устанавливает ingress-nginx
* Устанавливает cert-manager
* Устанавливает kube-prometheus-stack
* Устанавливает loki-stack

## Requirements

Providers:

* `kubernetes`
* `helm`

## Setup

Сначала нужно создать helm-релиз для cert_manager

1. `terraform apply -target module.yc_k8s_standard.helm_release.cert_manager`
1. `terraform apply`