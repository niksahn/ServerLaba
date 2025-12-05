#!/bin/bash

# Скрипт для переключения алгоритмов балансировки нагрузки в Nginx
# Использование: ./switch-nginx-algorithm.sh <algorithm>
# Алгоритмы: round-robin, weighted-round-robin, least-connections, ip-hash, random

NAMESPACE="microservices-lab"
NGINX_DEPLOYMENT="nginx"

if [ $# -eq 0 ]; then
    echo "Использование: $0 <algorithm>"
    echo "Доступные алгоритмы:"
    echo "  - round-robin"
    echo "  - weighted-round-robin"
    echo "  - least-connections"
    echo "  - ip-hash"
    echo "  - random"
    exit 1
fi

ALGORITHM=$1

case $ALGORITHM in
    round-robin)
        CONFIGMAP="nginx-config-round-robin"
        ;;
    weighted-round-robin)
        CONFIGMAP="nginx-config-weighted-round-robin"
        ;;
    least-connections)
        CONFIGMAP="nginx-config-least-connections"
        ;;
    ip-hash)
        CONFIGMAP="nginx-config-ip-hash"
        ;;
    random)
        CONFIGMAP="nginx-config-random"
        ;;
    *)
        echo "Неизвестный алгоритм: $ALGORITHM"
        echo "Доступные алгоритмы: round-robin, weighted-round-robin, least-connections, ip-hash, random"
        exit 1
        ;;
esac

echo "Переключение на алгоритм: $ALGORITHM"
echo "Использование ConfigMap: $CONFIGMAP"

# Проверяем существование ConfigMap
if ! kubectl get configmap "$CONFIGMAP" -n "$NAMESPACE" > /dev/null 2>&1; then
    echo "Ошибка: ConfigMap $CONFIGMAP не найден в namespace $NAMESPACE"
    echo "Убедитесь, что все ConfigMap файлы применены:"
    echo "  kubectl apply -f manifests/configs/nginx-config-*.yaml"
    exit 1
fi

# Обновляем volume в deployment для использования нового ConfigMap
kubectl patch deployment "$NGINX_DEPLOYMENT" -n "$NAMESPACE" -p "{\"spec\":{\"template\":{\"spec\":{\"volumes\":[{\"name\":\"nginx-config\",\"configMap\":{\"name\":\"$CONFIGMAP\"}}]}}}}"

# Перезапускаем поды Nginx для применения новой конфигурации
kubectl rollout restart deployment "$NGINX_DEPLOYMENT" -n "$NAMESPACE"

echo "Ожидание перезапуска Nginx..."
kubectl rollout status deployment "$NGINX_DEPLOYMENT" -n "$NAMESPACE"

echo "Алгоритм балансировки успешно переключен на: $ALGORITHM"











