#!/bin/bash

# Скрипт для пересборки и деплоя всех микросервисов в Kubernetes
# Использование: ./build-deploy-all.sh

set -e

echo "=== Пересборка и деплой всех микросервисов ==="

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Список сервисов для сборки
SERVICES=(
    "authservice"
    "userservice"
    "appservice"
    "api-gateway"
    "prolog"
)

for service in "${SERVICES[@]}"; do
    echo ""
    echo "=========================================="
    echo "Обработка сервиса: $service"
    echo "=========================================="
    
    if [ -f "$SCRIPT_DIR/build-deploy-$service.sh" ]; then
        bash "$SCRIPT_DIR/build-deploy-$service.sh"
    else
        echo "Предупреждение: Скрипт для $service не найден"
    fi
done

echo ""
echo "=== Все микросервисы успешно пересобраны и задеплоены ==="

