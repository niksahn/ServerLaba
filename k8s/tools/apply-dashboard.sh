#!/bin/bash

# Скрипт для применения обновленного Grafana dashboard

NAMESPACE="microservices-lab"

echo "Применение обновленного Grafana dashboard..."
echo ""

# Применяем ConfigMap
kubectl apply -f manifests/configs/grafana-dashboards-configmap.yaml -n $NAMESPACE

if [ $? -eq 0 ]; then
    echo "✓ ConfigMap применен успешно"
else
    echo "✗ Ошибка при применении ConfigMap"
    exit 1
fi

echo ""
echo "Перезапуск Grafana для загрузки нового dashboard..."
kubectl rollout restart deployment grafana -n $NAMESPACE

echo ""
echo "Ожидание готовности Grafana..."
kubectl rollout status deployment grafana -n $NAMESPACE

echo ""
echo "✓ Dashboard обновлен!"
echo ""
echo "Проверьте Grafana:"
echo "  1. Откройте Grafana dashboard 'Nginx Load Balancer'"
echo "  2. Прокрутите вниз, чтобы увидеть новые панели:"
echo "     - App Service - Распределение запросов по подам и нодам"
echo "     - User Service - Распределение запросов по подам и нодам"
echo "     - Auth Service - Распределение запросов по подам и нодам"
echo "     - Общее распределение запросов по нодам"








