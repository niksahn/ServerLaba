# Grafana Dashboards

Эта директория содержит отдельные файлы дашбордов Grafana.

## Структура

- `dashboards.yml` - конфигурация провайдера дашбордов
- `*.json` - файлы дашбордов Grafana

## Использование

### Редактирование дашбордов

Вы можете редактировать отдельные JSON файлы дашбордов в этой директории.

### Генерация ConfigMap

После изменения файлов дашбордов, выполните скрипт для генерации ConfigMap:

```bash
cd k8s
python generate-dashboards-configmap.py
```

Это создаст/обновит файл `grafana-dashboards-configmap.yaml` с актуальными данными из файлов в этой директории.

### Применение изменений

После генерации ConfigMap, примените его в Kubernetes:

```bash
kubectl apply -f grafana-dashboards-configmap.yaml
kubectl apply -f grafana-dashboards-provider-configmap.yaml
kubectl apply -f grafana-deployment.yaml
```

Или перезапустите под Grafana для применения изменений:

```bash
kubectl rollout restart deployment/grafana -n microservices-lab
```

## Файлы дашбордов

- `k8s-cluster-overview.json` - Обзор кластера Kubernetes
- `k8s-nodes.json` - Мониторинг узлов Kubernetes
- `k8s-pods.json` - Мониторинг подов Kubernetes
- `overview.json` - Обзор микросервисов
- `apigateway.json` - Дашборд API Gateway
- `authservice.json` - Дашборд Auth Service
- `appservice.json` - Дашборд App Service
- `userservice.json` - Дашборд User Service
- `debug.json` - Отладочный дашборд
- `nginx-load-balancer.json` - Дашборд NGINX Load Balancer
- `nginx-14900.json` - Дашборд Nginx (Grafana Dashboard ID 14900)





