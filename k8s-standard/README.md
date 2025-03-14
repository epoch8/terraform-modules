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
2. `terraform apply -target module.nl_k8s_standard.helm_release.kube_prometheus_stack`
3. `terraform apply`

---

Если на втором шаге во время создания ресурсов `kube-prometheus-stack-*` возникли ошибки `no matches for kind "ServiceMonitor" in version "monitoring.coreos.com/v1"`, то необходимо убедиться, что в провайдере helm выключена настройка `experiments manifest`:
```
  experiments {
    manifest = false
  }
```

---

Если на втором шаге при создании подов `prometheus-kube-prometheus-stack-prometheus-0` и `kube-prometheus-stack-grafana-*-*` возникает следующая ошибка и поды продолжают находиться в статусе `Pending`:
```
0/* nodes are available: pod has unbound immediate PersistentVolumeClaims. preemption: 0/* nodes are available: 2 Preemption is not helpful for scheduling.
```
То необходимо проверить Persistent Vlume Claims. Возможно отсутствует настройка storageClassName:
```
  storageClassName: <YOUR_STORAGE_CLASS_NAME>
```

---
