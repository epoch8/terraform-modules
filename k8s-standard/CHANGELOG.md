# 2026-01-12

* Добавлены параметры `loki_disk_size_gb`, `loki_retention_days`

# 2025-09-19

* Исправление типов переменных `kube_loki_stack_values_override` и `kube-kube_prometheus_stack_values_override-stack`

# 2025-08-25

* Добавлена возможность переопределения `values` для `kube-loki-stack` и `kube-prometheus-stack` в модуле **k8s-standard**

# 2025-07-13

* Добавили явное требование провайдеров `kubernetes` и `helm`

# 2025-04-22

* Для GKE добавлен `nodeSelector: cloud.google.com/gke-provisioning=standard`
  чтобы prometeus не шедулился на временные ноды
* Добавлен `priorityClass: high-priority-monitoring` чтобы prometheus мог
  вытеснить что-то с постоянной ноды при решедулинге

# 2025-04-21

* Добавлен экспорт названия нодпула для GKE кластера в kube-state-metrics

# 2024-11-15

* Добавлена переменная `kube_prometheus_stack_enabled` которой можно отключить
  разворачивание kube-prometheus-stack

# 2024-11-11

* Создание DNS записей в google вынесено в модуль [gcp-dns-entry](..%2Fgcp-dns-entry). Пример:

```
provider "google" {
  project = "e8-gke"
}
module "my_project_ingress_dns" {
  source = "git@github.com:epoch8/terraform-modules.git//gcp-dns-entry?ref=2024-11-11"

  managed_zone_name = "epoch8-dev"
  dns_name          = "my_project.epoch8.dev."
  ingress_ip        = module.my_project_k8s_standard.ingress_ip
}
```


# 2024-10-19

* Включен мониторинг в ingress-nginx

# 2024-07-05.4

* Добавлена параметризация версий для cert-manager, ingress-nginx, prometheus,
  loki

# 2023-08-18

* Исправлен PVC для loki-stack

# 2023-08-16

* Для ingress_nginx выставлен параметр `enable-underscores-in-headers = true`

# 2023-07-27

* Зафиксирована версия helm chart для ingress-nginx==4.7.1
* Увеличена версия helm chart для kube-prometheus-stack==48.2.2
* Добавлен параметр для неймспейса kube-prometheus-stack

# 2023-07-06

* Добавлен loki-stack для сбора логов k8s

# 2023-06-01

* Добавлена DNS запись `*.${base_domain}` -> `CNAME ingress_dns`

# 2023-05-31

* Добавлен kube-prometheus-stack для стандартного мониторинга
* Новая переменная `admin_email` - используется при взаимодействии с let's encrypt

# 2023-04-13

* Добавлен output параметр `ingress_dns` который указывает на DNS имя балансера
  ингресса
