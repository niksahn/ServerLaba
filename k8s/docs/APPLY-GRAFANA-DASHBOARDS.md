# Применение изменений Grafana Dashboards

## Структура

Дашборды Grafana теперь разделены на отдельные файлы в директории `grafana-dashboards/`:

- `dashboards.yml` - конфигурация провайдера (отдельный ConfigMap)
- `*.json` - отдельные файлы дашбордов

## Применение изменений

### 1. Редактирование дашбордов

Редактируйте JSON файлы в `grafana-dashboards/` по необходимости.

### 2. Генерация ConfigMap

После изменения файлов выполните:

```bash
cd k8s
python generate-dashboards-configmap.py
```

Это обновит `grafana-dashboards-configmap.yaml` с актуальными данными.

### 3. Применение в Kubernetes

```bash
# Применить ConfigMap для провайдера
kubectl apply -f grafana-dashboards-provider-configmap.yaml

# Применить ConfigMap с дашбордами
kubectl apply -f grafana-dashboards-configmap.yaml

# Применить Deployment (если нужно)
kubectl apply -f grafana-deployment.yaml

# Или перезапустить под для применения изменений
kubectl rollout restart deployment/grafana -n microservices-lab
```

## Преимущества новой структуры

1. ✅ Модульность - каждый дашборд в отдельном файле
2. ✅ Удобство редактирования - можно редактировать отдельные дашборды
3. ✅ Версионирование - изменения в отдельных файлах видны в git
4. ✅ Автоматизация - скрипт генерирует ConfigMap из файлов





