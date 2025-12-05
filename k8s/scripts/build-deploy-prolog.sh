#!/bin/bash

# Скрипт для пересборки и деплоя Prolog Server в Kubernetes
# Использование: ./build-deploy-prolog.sh

set -e

SERVICE_NAME="prolog"
IMAGE_NAME="servers-prolog-server"
IMAGE_TAG="latest"
DEPLOYMENT_FILE="manifests/apps/prolog-deployment.yaml"
SERVICE_DIR="prolog"

echo "=== Пересборка и деплой Prolog Server ==="

# Сохранение корневой директории проекта
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
K8S_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Переход в директорию сервиса
cd "$PROJECT_ROOT/$SERVICE_DIR"

echo "Сборка Docker образа..."
docker build -t "$IMAGE_NAME:$IMAGE_TAG" -f Dockerfile .

echo "Загрузка образа в minikube..."
minikube image load "$IMAGE_NAME:$IMAGE_TAG" || {
    echo "Попытка альтернативного способа загрузки..."
    docker save "$IMAGE_NAME:$IMAGE_TAG" | minikube image load
}

# Возврат в директорию k8s
cd "$K8S_DIR"

echo "Применение deployment..."
kubectl apply -f "$K8S_DIR/$DEPLOYMENT_FILE"

echo "Перезапуск deployment для применения нового образа..."
kubectl rollout restart deployment prolog-server -n microservices-lab

echo "Ожидание готовности deployment..."
kubectl rollout status deployment prolog-server -n microservices-lab --timeout=300s

echo "=== Prolog Server успешно пересобран и задеплоен ==="

