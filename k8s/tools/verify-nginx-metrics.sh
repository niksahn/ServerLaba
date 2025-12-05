#!/bin/bash

# Скрипт для проверки работы метрик Nginx

NAMESPACE="microservices-lab"

echo "=========================================="
echo "Проверка метрик Nginx"
echo "=========================================="
echo ""

echo "1. Проверка статуса экспортера..."
kubectl get pods -n $NAMESPACE -l app=nginx-prometheus-exporter

echo ""
echo "2. Проверка логов экспортера..."
kubectl logs -n $NAMESPACE -l app=nginx-prometheus-exporter --tail=5

echo ""
echo "3. Проверка метрик экспортера..."
POD=$(kubectl get pods -n $NAMESPACE -l app=nginx-prometheus-exporter -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ ! -z "$POD" ]; then
    echo "   Метрики из пода $POD:"
    kubectl exec -n $NAMESPACE $POD -- wget -qO- http://localhost:9113/metrics 2>/dev/null | grep "^nginx_" | head -5
else
    echo "   Под не найден"
fi

echo ""
echo "4. Проверка сервиса nginx (порт 8080)..."
kubectl get svc nginx -n $NAMESPACE

echo ""
echo "5. Проверка endpoints nginx..."
kubectl get endpoints nginx -n $NAMESPACE

echo ""
echo "6. Проверка конфигурации Prometheus..."
kubectl get configmap prometheus-config -n $NAMESPACE -o jsonpath='{.data.prometheus\.yml}' | grep -A 3 "job_name: 'nginx'"

echo ""
echo "=========================================="
echo "Для проверки метрик в Prometheus:"
echo "  kubectl port-forward -n $NAMESPACE svc/prometheus 9090:9090"
echo "  Откройте: http://localhost:9090"
echo "  Выполните запрос: nginx_connections_accepted"
echo ""
echo "Для проверки дашборда в Grafana:"
echo "  Откройте дашборд 'Nginx' (ID 14900)"
echo "  Выберите instance: nginx-prometheus-exporter:9113"
echo "=========================================="


