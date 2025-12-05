#!/bin/bash

# Скрипт для применения панелей распределения запросов

NAMESPACE="microservices-lab"

echo "=========================================="
echo "Применение панелей распределения запросов"
echo "=========================================="
echo ""

echo "1. Обновление конфигурации Prometheus..."
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
echo "4. Обновление дашбордов Grafana..."
kubectl apply -f manifests/configs/grafana-dashboards-configmap.yaml -n $NAMESPACE

if [ $? -eq 0 ]; then
    echo "   ✓ Дашборды обновлены"
else
    echo "   ✗ Ошибка при обновлении дашбордов"
    exit 1
fi

echo ""
echo "5. Перезапуск Grafana..."
kubectl rollout restart deployment grafana -n $NAMESPACE

if [ $? -eq 0 ]; then
    echo "   ✓ Grafana перезапущена"
else
    echo "   ⚠ Ошибка при перезапуске Grafana"
fi

echo ""
echo "6. Ожидание готовности Grafana..."
kubectl rollout status deployment grafana -n $NAMESPACE --timeout=120s

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
echo "Новые панели в дашборде:"
echo "  - Request Distribution by Services (строка)"
echo "  - App Service - Request Distribution by Pods (%) (bar gauge)"
echo "  - User Service - Request Distribution by Pods (%) (bar gauge)"
echo "  - Auth Service - Request Distribution by Pods (%) (bar gauge)"
echo "  - Prolog Service - Request Distribution by Pods (%) (bar gauge)"
echo "  - App Service - Request Distribution (%) (pie chart)"
echo "  - User Service - Request Distribution (%) (pie chart)"
echo "  - Auth Service - Request Distribution (%) (pie chart)"
echo "  - Prolog Service - Request Distribution (%) (pie chart)"
echo "  - Overall Request Distribution by Service (%) (pie chart)"
echo ""
echo "Примечание:"
echo "  - Метрики появятся после того, как Prometheus соберет данные со всех подов"
echo "  - Убедитесь, что все поды сервисов запущены и доступны"
echo "  - Проверьте в Prometheus, что все поды собираются:"
echo "    kubectl port-forward -n $NAMESPACE svc/prometheus 9090:9090"
echo "    Откройте: http://localhost:9090"
echo "    Выполните запрос: up{job=\"app-service\"}"
echo ""


