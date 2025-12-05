# Настройка метрик Nginx для Grafana дашборда

## Проблема

Дашборд Nginx (ID 14900) показывает "no data", потому что Prometheus пытается собирать метрики напрямую с `/nginx_status`, который возвращает текстовый формат, а не Prometheus метрики.

## Решение

Используется `nginx-prometheus-exporter`, который преобразует stub_status в формат Prometheus.

## Шаги установки

### 1. Применить nginx-prometheus-exporter

```bash
kubectl apply -f nginx-prometheus-exporter-deployment.yaml -n microservices-lab
```

### 2. Обновить конфигурацию Prometheus

```bash
kubectl apply -f prometheus-configmap.yaml -n microservices-lab
kubectl rollout restart deployment prometheus -n microservices-lab
```

### 3. Или использовать автоматический скрипт

```bash
./setup-nginx-metrics.sh
```

## Проверка работы

### Проверка экспортера

```bash
kubectl port-forward -n microservices-lab svc/nginx-prometheus-exporter 9113:9113
```

Откройте в браузере: http://localhost:9113/metrics

Должны быть видны метрики:
- `nginx_connections_accepted`
- `nginx_connections_handled`
- `nginx_http_requests_total`
- `nginx_connections_active`
- `nginx_connections_reading`
- `nginx_connections_waiting`
- `nginx_connections_writing`

### Проверка в Prometheus

```bash
kubectl port-forward -n microservices-lab svc/prometheus 9090:9090
```

Откройте: http://localhost:9090

Выполните запросы:
- `nginx_connections_accepted`
- `nginx_http_requests_total`
- `nginx_connections_active`

### Проверка дашборда

1. Откройте Grafana
2. Перейдите в дашборд "Nginx" (ID 14900)
3. Метрики должны появиться в течение 1-2 минут

## Примечания

- Дашборд также использует метрики `nginxlog_resp_bytes` из логов, которые требуют Telegraf. Эти метрики могут не работать без дополнительной настройки Telegraf.
- Основные метрики из stub_status (connections, requests) должны работать сразу после установки экспортера.


