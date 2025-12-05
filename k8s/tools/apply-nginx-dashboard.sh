#!/bin/bash

# Скрипт для применения обновленного Grafana dashboard (включая новый Nginx дашборд)

NAMESPACE="microservices-lab"

echo "=========================================="
echo "Применение обновленного Grafana dashboard"
echo "=========================================="
echo ""

# Проверяем наличие ConfigMap файла
if [ ! -f "manifests/configs/grafana-dashboards-configmap.yaml" ]; then
    echo "✗ Ошибка: файл manifests/configs/grafana-dashboards-configmap.yaml не найден!"
    echo "  Запустите сначала: python tools/generate-dashboards-configmap.py"
    exit 1
fi

# Проверяем, что новый дашборд присутствует в ConfigMap
if ! grep -q "nginx-14900.json" manifests/configs/grafana-dashboards-configmap.yaml; then
    echo "⚠ Предупреждение: nginx-14900.json не найден в ConfigMap!"
    echo "  Запустите: python tools/generate-dashboards-configmap.py"
    echo ""
    read -p "Продолжить применение ConfigMap? (y/n) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo "1. Применение ConfigMap с дашбордами..."
kubectl apply -f manifests/configs/grafana-dashboards-configmap.yaml -n $NAMESPACE

if [ $? -eq 0 ]; then
    echo "   ✓ ConfigMap применен успешно"
else
    echo "   ✗ Ошибка при применении ConfigMap"
    exit 1
fi

echo ""
echo "2. Проверка ConfigMap в кластере..."
kubectl get configmap grafana-dashboards -n $NAMESPACE -o jsonpath='{.data}' | grep -q "nginx-14900.json"
if [ $? -eq 0 ]; then
    echo "   ✓ Дашборд nginx-14900.json найден в ConfigMap кластера"
else
    echo "   ⚠ Дашборд nginx-14900.json не найден в ConfigMap кластера"
fi

echo ""
echo "3. Перезапуск Grafana для загрузки нового dashboard..."
kubectl rollout restart deployment grafana -n $NAMESPACE

echo ""
echo "4. Ожидание готовности Grafana..."
kubectl rollout status deployment grafana -n $NAMESPACE --timeout=120s

if [ $? -eq 0 ]; then
    echo "   ✓ Grafana перезапущена и готова"
else
    echo "   ⚠ Таймаут ожидания готовности Grafana"
fi

echo ""
echo "=========================================="
echo "✓ Процесс завершен!"
echo "=========================================="
echo ""
echo "Инструкции:"
echo "  1. Откройте Grafana в браузере"
echo "  2. Перейдите в раздел Dashboards (значок меню слева)"
echo "  3. Найдите дашборд 'Nginx' (Grafana Dashboard ID 14900)"
echo ""
echo "Если дашборд не появился:"
echo "  - Подождите до 30 секунд (интервал обновления провайдера)"
echo "  - Проверьте логи Grafana: kubectl logs -n $NAMESPACE deployment/grafana"
echo "  - Проверьте, что ConfigMap смонтирован: kubectl exec -n $NAMESPACE deployment/grafana -- ls -la /var/lib/grafana/dashboards/"
echo ""


