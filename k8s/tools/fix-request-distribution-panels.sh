#!/bin/bash

# Скрипт для исправления панелей распределения запросов

NAMESPACE="microservices-lab"

echo "=========================================="
echo "Исправление панелей распределения запросов"
echo "=========================================="
echo ""

echo "1. Обновление конфигурации Prometheus (статический список всех подов)..."
kubectl apply -f manifests/configs/prometheus-configmap.yaml -n $NAMESPACE

if [ $? -eq 0 ]; then
    echo "   ✓ Конфигурация Prometheus обновлена"
else
    echo "   ✗ Ошибка при обновлении конфигурации Prometheus"
    exit 1
fi

echo ""
echo "2. Перезапуск Prometheus..."
kubectl rollout restart deployment prometheus -n $NAMESPACE

if [ $? -eq 0 ]; then
    echo "   ✓ Prometheus перезапущен"
else
    echo "   ⚠ Ошибка при перезапуске Prometheus"
fi

echo ""
echo "3. Ожидание готовности Prometheus..."
kubectl rollout status deployment prometheus -n $NAMESPACE --timeout=120s

if [ $? -eq 0 ]; then
    echo "   ✓ Prometheus готов"
else
    echo "   ⚠ Таймаут ожидания (возможно, под еще запускается)"
fi

echo ""
echo "4. Проверка доступности подов..."
echo "   Проверяю app-service поды:"
kubectl get pods -n $NAMESPACE -l app=servers-app-1 --no-headers | awk '{print "     - " $1}'
echo "   Проверяю user-service поды:"
kubectl get pods -n $NAMESPACE -l app=servers-user-service-1 --no-headers | awk '{print "     - " $1}'
echo "   Проверяю authservice поды:"
kubectl get pods -n $NAMESPACE -l app=servers-authservice-1 --no-headers | awk '{print "     - " $1}'

echo ""
echo "5. Обновление дашбордов Grafana..."
kubectl apply -f manifests/configs/grafana-dashboards-configmap.yaml -n $NAMESPACE

if [ $? -eq 0 ]; then
    echo "   ✓ Дашборды обновлены"
else
    echo "   ✗ Ошибка при обновлении дашбордов"
    exit 1
fi

echo ""
echo "6. Перезапуск Grafana..."
kubectl rollout restart deployment grafana -n $NAMESPACE

if [ $? -eq 0 ]; then
    echo "   ✓ Grafana перезапущена"
else
    echo "   ⚠ Ошибка при перезапуске Grafana"
fi

echo ""
echo "7. Ожидание готовности Grafana..."
kubectl rollout status deployment grafana -n $NAMESPACE --timeout=120s

if [ $? -eq 0 ]; then
    echo "   ✓ Grafana готова"
else
    echo "   ⚠ Таймаут ожидания (возможно, под еще запускается)"
fi

echo ""
echo "=========================================="
echo "✓ Исправления применены!"
echo "=========================================="
echo ""
echo "Что было исправлено:"
echo "  1. Prometheus теперь собирает метрики со всех подов (статический список)"
echo "  2. Запросы в панелях обновлены для правильной работы с метриками"
echo "  3. Добавлена поддержка разных метрик для authservice"
echo ""
echo "Проверка работы:"
echo "  1. Проверьте метрики в Prometheus:"
echo "     kubectl port-forward -n $NAMESPACE svc/prometheus 9090:9090"
echo "     Откройте: http://localhost:9090"
echo "     Выполните запросы:"
echo "       - up{job=\"app-service\"}"
echo "       - ktor_http_server_requests_seconds_count{job=\"app-service\"}"
echo "       - http_requests_received_total{job=\"authservice\"}"
echo ""
echo "  2. Проверьте панели в Grafana:"
echo "     Панели должны показывать распределение запросов по подам"
echo ""
echo "  3. Если метрики все еще не работают:"
echo "     - Убедитесь, что все поды запущены и доступны"
echo "     - Проверьте, что метрики экспортируются на правильных портах"
echo "     - Проверьте логи Prometheus: kubectl logs -n $NAMESPACE deployment/prometheus"
echo ""


