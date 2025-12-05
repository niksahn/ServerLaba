#!/bin/bash

# Полный скрипт для настройки метрик Nginx и применения обновленного дашборда

NAMESPACE="microservices-lab"

echo "=========================================="
echo "Настройка метрик Nginx для Grafana"
echo "=========================================="
echo ""

# Шаг 1: Применение nginx-prometheus-exporter
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
kubectl wait --for=condition=available --timeout=120s deployment/nginx-prometheus-exporter -n $NAMESPACE 2>/dev/null

if [ $? -eq 0 ]; then
    echo "   ✓ nginx-prometheus-exporter готов"
else
    echo "   ⚠ Таймаут ожидания (возможно, под еще запускается)"
fi

# Шаг 2: Обновление конфигурации Prometheus
echo ""
echo "3. Обновление конфигурации Prometheus..."
kubectl apply -f manifests/configs/prometheus-configmap.yaml -n $NAMESPACE

if [ $? -eq 0 ]; then
    echo "   ✓ Конфигурация Prometheus обновлена"
else
    echo "   ✗ Ошибка при обновлении конфигурации Prometheus"
    exit 1
fi

# Шаг 3: Перезапуск Prometheus
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
kubectl rollout status deployment prometheus -n $NAMESPACE --timeout=120s 2>/dev/null

if [ $? -eq 0 ]; then
    echo "   ✓ Prometheus готов"
else
    echo "   ⚠ Таймаут ожидания (возможно, под еще запускается)"
fi

# Шаг 4: Обновление дашборда Grafana
echo ""
echo "6. Обновление дашборда Grafana..."
kubectl apply -f manifests/configs/grafana-dashboards-configmap.yaml -n $NAMESPACE

if [ $? -eq 0 ]; then
    echo "   ✓ ConfigMap с дашбордами обновлен"
else
    echo "   ✗ Ошибка при обновлении ConfigMap"
    exit 1
fi

# Шаг 5: Перезапуск Grafana
echo ""
echo "7. Перезапуск Grafana для загрузки обновленного дашборда..."
kubectl rollout restart deployment grafana -n $NAMESPACE

if [ $? -eq 0 ]; then
    echo "   ✓ Grafana перезапущена"
else
    echo "   ⚠ Ошибка при перезапуске Grafana"
fi

echo ""
echo "8. Ожидание готовности Grafana..."
kubectl rollout status deployment grafana -n $NAMESPACE --timeout=120s 2>/dev/null

if [ $? -eq 0 ]; then
    echo "   ✓ Grafana готова"
else
    echo "   ⚠ Таймаут ожидания (возможно, под еще запускается)"
fi

echo ""
echo "=========================================="
echo "✓ Настройка завершена!"
echo "=========================================="
echo ""
echo "Следующие шаги:"
echo ""
echo "1. Подождите 1-2 минуты для сбора первых метрик"
echo ""
echo "2. Проверьте метрики экспортера:"
echo "   kubectl port-forward -n $NAMESPACE svc/nginx-prometheus-exporter 9113:9113"
echo "   Откройте: http://localhost:9113/metrics"
echo "   Должны быть видны метрики nginx_connections_* и nginx_http_requests_total"
echo ""
echo "3. Проверьте метрики в Prometheus:"
echo "   kubectl port-forward -n $NAMESPACE svc/prometheus 9090:9090"
echo "   Откройте: http://localhost:9090"
echo "   Выполните запрос: nginx_connections_accepted"
echo ""
echo "4. Откройте дашборд в Grafana:"
echo "   - Перейдите в раздел Dashboards"
echo "   - Найдите дашборд 'Nginx' (ID 14900)"
echo "   - Выберите instance: nginx-prometheus-exporter:9113"
echo ""
echo "Примечание:"
echo "  - Метрики nginxlog_resp_bytes (из логов) могут не работать без Telegraf"
echo "  - Основные метрики из stub_status должны работать сразу"
echo ""


