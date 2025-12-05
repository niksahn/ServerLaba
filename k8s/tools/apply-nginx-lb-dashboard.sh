#!/bin/bash

# Скрипт для применения дашборда Nginx Load Balancer

set -e

NAMESPACE="microservices-lab"
DASHBOARD_FILE="k8s/dashboards/nginx-load-balancer-pods.json"
CONFIGMAP_NAME="grafana-dashboard-nginx-lb"

echo "🚀 Применение дашборда Nginx Load Balancer..."

# Проверка существования файла дашборда
if [ ! -f "$DASHBOARD_FILE" ]; then
    echo "❌ Ошибка: файл дашборда не найден: $DASHBOARD_FILE"
    exit 1
fi

# Шаг 1: Применить обновленные конфигурации
echo ""
echo "📝 Шаг 1: Применение обновленных конфигураций..."

echo "  → Применение конфигурации Nginx..."
kubectl apply -f k8s/manifests/configs/nginx-configmap.yaml

echo "  → Применение конфигурации Telegraf..."
kubectl apply -f k8s/manifests/configs/telegraf-nginx-configmap.yaml

# Шаг 2: Перезапуск Nginx
echo ""
echo "🔄 Шаг 2: Перезапуск Nginx..."
kubectl rollout restart deployment/nginx -n $NAMESPACE

echo "  → Ожидание готовности Nginx..."
kubectl rollout status deployment/nginx -n $NAMESPACE --timeout=120s

# Шаг 3: Создание/обновление ConfigMap с дашбордом
echo ""
echo "📊 Шаг 3: Создание ConfigMap с дашбордом..."

# Удалить старый ConfigMap если существует
kubectl delete configmap $CONFIGMAP_NAME -n $NAMESPACE --ignore-not-found=true

# Создать новый ConfigMap
kubectl create configmap $CONFIGMAP_NAME \
  --from-file=nginx-load-balancer-pods.json=$DASHBOARD_FILE \
  -n $NAMESPACE

# Добавить label для автоматического обнаружения Grafana
kubectl label configmap $CONFIGMAP_NAME \
  grafana_dashboard=1 \
  -n $NAMESPACE

echo "  ✅ ConfigMap создан: $CONFIGMAP_NAME"

# Шаг 4: Проверка Grafana
echo ""
echo "🔍 Шаг 4: Проверка Grafana..."

GRAFANA_POD=$(kubectl get pods -n $NAMESPACE -l app=grafana -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")

if [ -z "$GRAFANA_POD" ]; then
    echo "  ⚠️  Предупреждение: Grafana не найдена в namespace $NAMESPACE"
    echo "  Дашборд будет доступен после запуска Grafana"
else
    echo "  → Перезапуск Grafana для загрузки дашборда..."
    kubectl rollout restart deployment/grafana -n $NAMESPACE
    
    echo "  → Ожидание готовности Grafana..."
    kubectl rollout status deployment/grafana -n $NAMESPACE --timeout=120s
    
    echo "  ✅ Grafana перезапущена"
fi

# Шаг 5: Проверка метрик
echo ""
echo "🔍 Шаг 5: Проверка метрик Telegraf..."

NGINX_POD=$(kubectl get pods -n $NAMESPACE -l app=nginx -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")

if [ -z "$NGINX_POD" ]; then
    echo "  ⚠️  Предупреждение: Nginx pod не найден"
else
    echo "  → Проверка логов Telegraf..."
    kubectl logs -n $NAMESPACE $NGINX_POD -c telegraf --tail=10 | grep -i "error" && echo "  ⚠️  Обнаружены ошибки в Telegraf" || echo "  ✅ Telegraf работает без ошибок"
fi

# Финальная информация
echo ""
echo "✅ Дашборд успешно применен!"
echo ""
echo "📋 Следующие шаги:"
echo ""
echo "1. Откройте Grafana:"
echo "   kubectl port-forward -n $NAMESPACE svc/grafana 3000:3000"
echo "   Затем откройте http://localhost:3000"
echo ""
echo "2. Найдите дашборд:"
echo "   Dashboards → Browse → 'Nginx Load Balancer - Распределение по подам'"
echo ""
echo "3. Для генерации тестового трафика:"
echo "   kubectl run -it --rm load-test --image=busybox --restart=Never -- sh -c \\"
echo "     'while true; do wget -q -O- http://nginx/app-service/health; sleep 0.1; done'"
echo ""
echo "4. Для проверки метрик напрямую:"
echo "   kubectl port-forward -n $NAMESPACE svc/nginx 9273:9273"
echo "   curl http://localhost:9273/metrics | grep nginxlog"
echo ""
echo "📖 Подробная документация: k8s/docs/NGINX-LOAD-BALANCER-DASHBOARD.md"
