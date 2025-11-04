#!/bin/bash

# Скрипт для развертывания всех компонентов в Kubernetes
# Использование: ./deploy.sh

set -e

echo "=== Развертывание микросервисов в Kubernetes ==="

# Создание namespace
echo "Создание namespace..."
kubectl apply -f namespace.yaml

# Применение ConfigMap
echo "Применение ConfigMap..."
kubectl apply -f configmap.yaml

# Развертывание инфраструктурных сервисов
echo "Развертывание MongoDB..."
kubectl apply -f mongodb-deployment.yaml

echo "Развертывание Redis..."
kubectl apply -f redis-deployment.yaml

echo "Развертывание Zookeeper..."
kubectl apply -f zookeeper-deployment.yaml

echo "Ожидание готовности Zookeeper..."

echo "Развертывание Kafka..."
kubectl apply -f kafka-deployment.yaml

# Ожидание готовности инфраструктурных сервисов
echo "Ожидание готовности инфраструктурных сервисов..."
sleep 10

# Развертывание микросервисов
echo "Развертывание AuthService..."
kubectl apply -f authservice-deployment.yaml

echo "Развертывание UserService..."
kubectl apply -f userservice-deployment.yaml

echo "Развертывание AppService..."
kubectl apply -f app-service-deployment.yaml

echo "Развертывание API Gateway..."
kubectl apply -f api-gateway-deployment.yaml

echo "Развертывание Prolog Server..."
kubectl apply -f prolog-deployment.yaml

# Развертывание мониторинга
echo "Развертывание Prometheus..."
kubectl apply -f prometheus-configmap.yaml
kubectl apply -f prometheus-deployment.yaml

echo "Развертывание kube-state-metrics (опционально, для метрик Kubernetes)..."
kubectl apply -f kube-state-metrics-deployment.yaml || echo "kube-state-metrics не установлен (это нормально для minikube)"

echo "Развертывание Grafana..."
kubectl apply -f grafana-dashboards-configmap.yaml
kubectl apply -f grafana-deployment.yaml

echo ""
echo "=== Развертывание завершено ==="
echo ""
echo "Проверка статуса подов:"
kubectl get pods -n microservices-lab

echo ""
echo "Ожидание готовности всех подов..."
kubectl wait --for=condition=ready pod --all -n microservices-lab --timeout=300s || true

echo ""
echo "=== Статус развертывания ==="
kubectl get all -n microservices-lab

