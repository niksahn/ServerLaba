#!/bin/bash

# Скрипт для настройки сбора метрик из логов Nginx через Telegraf

NAMESPACE="microservices-lab"

echo "=========================================="
echo "Настройка метрик из логов Nginx"
echo "=========================================="
echo ""

echo "1. Применение конфигурации Telegraf..."
kubectl apply -f manifests/configs/telegraf-nginx-configmap.yaml -n $NAMESPACE

if [ $? -eq 0 ]; then
    echo "   ✓ ConfigMap для Telegraf применен"
else
    echo "   ✗ Ошибка при применении ConfigMap"
    exit 1
fi

echo ""
echo "2. Обновление deployment Nginx с sidecar Telegraf..."
kubectl apply -f manifests/infra/nginx-deployment.yaml -n $NAMESPACE

if [ $? -eq 0 ]; then
    echo "   ✓ Deployment Nginx обновлен"
else
    echo "   ✗ Ошибка при обновлении deployment"
    exit 1
fi

echo ""
echo "3. Ожидание готовности Nginx с Telegraf..."
kubectl rollout status deployment nginx -n $NAMESPACE --timeout=120s

if [ $? -eq 0 ]; then
    echo "   ✓ Nginx с Telegraf готов"
else
    echo "   ⚠ Таймаут ожидания (возможно, под еще запускается)"
fi

echo ""
echo "4. Обновление конфигурации Prometheus..."
kubectl apply -f manifests/configs/prometheus-configmap.yaml -n $NAMESPACE

if [ $? -eq 0 ]; then
    echo "   ✓ Конфигурация Prometheus обновлена"
else
    echo "   ✗ Ошибка при обновлении конфигурации Prometheus"
    exit 1
fi

echo ""
echo "5. Перезапуск Prometheus..."
kubectl rollout restart deployment prometheus -n $NAMESPACE

if [ $? -eq 0 ]; then
    echo "   ✓ Prometheus перезапущен"
else
    echo "   ⚠ Ошибка при перезапуске Prometheus"
fi

echo ""
echo "6. Ожидание готовности Prometheus..."
kubectl rollout status deployment prometheus -n $NAMESPACE --timeout=120s

if [ $? -eq 0 ]; then
    echo "   ✓ Prometheus готов"
else
    echo "   ⚠ Таймаут ожидания (возможно, под еще запускается)"
fi

echo ""
echo "=========================================="
echo "✓ Настройка завершена!"
echo "=========================================="
echo ""
echo "Проверка работы:"
echo "  1. Проверьте метрики Telegraf:"
echo "     kubectl port-forward -n $NAMESPACE svc/nginx 9273:9273"
echo "     Откройте: http://localhost:9273/metrics"
echo "     Должны быть видны метрики с префиксом tail_"
echo ""
echo "  2. Проверьте метрики в Prometheus:"
echo "     kubectl port-forward -n $NAMESPACE svc/prometheus 9090:9090"
echo "     Откройте: http://localhost:9090"
echo "     Выполните запрос: tail_resp_bytes"
echo ""
echo "  3. Откройте дашборд в Grafana:"
echo "     Панель 'Each Request Detail' должна показывать данные"
echo ""
echo "Примечание:"
echo "  - Метрики появятся после того, как Nginx обработает несколько запросов"
echo "  - Убедитесь, что есть трафик на Nginx для генерации логов"
echo ""


