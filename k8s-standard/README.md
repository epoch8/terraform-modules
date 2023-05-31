# Модуль `k8s-standard`

* Устанавливает ingress-nginx
* Устанавливает cert-manager
* Прописывает DNS ingress-nginx.XXX.epoch8.dev
* Прописывает DNS *.XXX.epoch8.dev
* Устанавливает kube-prometheus-stack

## Requirements

Providers:

* `google`
* `kubernetes`
* `helm`

## Setup

Сначала нужно создать helm-релиз для cert_manager

1. `terraform apply -target module.yc_k8s_standard.helm_release.cert_manager`
1. `terraform apply`