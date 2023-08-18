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
