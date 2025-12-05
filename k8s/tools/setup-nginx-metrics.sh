#!/bin/bash

# Скрипт для настройки метрик Nginx для Grafana дашборда

NAMESPACE="microservices-lab"

echo "=========================================="
echo "Настройка метрик Nginx для Grafana"
echo "=========================================="
echo ""

echo "1. Применение nginx-prometheus-exporter..."
kubectl apply -f manifests/infra/nginx-prometheus-exporter-deployment.yaml -n $NAMESPACE

if [ $? -eq 0 ]; then
    echo "   ✓ nginx-prometheus-exporter развернут"
else
    echo "   ✗ Ошибка при развертывании nginx-prometheus-exporter"
    exit 1
fi

echo ""
echo "2. Ожидание готовности nginx-prometheus-exporter..."
kubectl wait --for=condition=available --timeout=120s deployment/nginx-prometheus-exporter -n $NAMESPACE

if [ $? -eq 0 ]; then
    echo "   ✓ nginx-prometheus-exporter готов"
else
    echo "   ⚠ Таймаут ожидания готовности nginx-prometheus-exporter"
fi

echo ""
echo "3. Обновление конфигурации Prometheus..."
kubectl apply -f manifests/configs/prometheus-configmap.yaml -n $NAMESPACE

if [ $? -eq 0 ]; then
    echo "   ✓ Конфигурация Prometheus обновлена"
else
    echo "   ✗ Ошибка при обновлении конфигурации Prometheus"
    exit 1
fi

echo ""
echo "4. Перезапуск Prometheus для применения новой конфигурации..."
kubectl rollout restart deployment prometheus -n $NAMESPACE

if [ $? -eq 0 ]; then
    echo "   ✓ Prometheus перезапущен"
else
    echo "   ⚠ Ошибка при перезапуске Prometheus"
fi

echo ""
echo "5. Ожидание готовности Prometheus..."
kubectl rollout status deployment prometheus -n $NAMESPACE --timeout=120s

if [ $? -eq 0 ]; then
    echo "   ✓ Prometheus готов"
else
    echo "   ⚠ Таймаут ожидания готовности Prometheus"
fi

echo ""
echo "=========================================="
echo "✓ Настройка завершена!"
echo "=========================================="
echo ""
echo "Проверка метрик:"
echo "  1. Проверьте метрики экспортера:"
echo "     kubectl port-forward -n $NAMESPACE svc/nginx-prometheus-exporter 9113:9113"
echo "     Затем откройте: http://localhost:9113/metrics"
echo ""
echo "  2. Проверьте метрики в Prometheus:"
echo "     kubectl port-forward -n $NAMESPACE svc/prometheus 9090:9090"
echo "     Затем откройте: http://localhost:9090"
echo "     Выполните запрос: nginx_connections_accepted"
echo ""
echo "  3. Проверьте дашборд в Grafana:"
echo "     Откройте дашборд 'Nginx' (ID 14900)"
echo "     Метрики должны появиться в течение 1-2 минут"
echo ""


