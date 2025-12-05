#!/bin/bash

# Скрипт для решения проблемы с загрузкой образа nginx-prometheus-exporter

echo "=========================================="
echo "Решение проблемы с загрузкой образа"
echo "=========================================="
echo ""

echo "Вариант 1: Загрузка образа вручную на узел"
echo "--------------------------------------------"
echo "Если вы используете minikube или локальный кластер:"
echo ""
echo "  minikube ssh"
echo "  docker pull nginx/nginx-prometheus-exporter:latest"
echo "  exit"
echo ""
echo "Или для обычного Kubernetes кластера:"
echo "  ssh <node-name>"
echo "  docker pull nginx/nginx-prometheus-exporter:latest"
echo "  exit"
echo ""

read -p "Хотите попробовать загрузить образ сейчас? (y/n) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Проверяем, используется ли minikube
    if command -v minikube &> /dev/null; then
        echo "Обнаружен minikube. Загружаю образ..."
        minikube ssh -- "docker pull nginx/nginx-prometheus-exporter:latest"
        if [ $? -eq 0 ]; then
            echo "✓ Образ успешно загружен в minikube"
        else
            echo "✗ Ошибка при загрузке образа"
        fi
    else
        echo "Minikube не обнаружен. Загрузите образ вручную на узел кластера."
    fi
fi

echo ""
echo "Вариант 2: Использование альтернативного образа"
echo "--------------------------------------------"
echo "Если проблема сохраняется, можно использовать альтернативный образ:"
echo "  - quay.io/nginx/nginx-prometheus-exporter:latest"
echo "  - или другой доступный репозиторий"
echo ""

echo "Вариант 3: Проверка текущего deployment"
echo "--------------------------------------------"
echo "Проверяю текущий статус..."
kubectl get deployment nginx-prometheus-exporter -n microservices-lab 2>/dev/null

if [ $? -eq 0 ]; then
    echo ""
    echo "Просмотр событий для диагностики:"
    kubectl describe deployment nginx-prometheus-exporter -n microservices-lab | grep -A 10 "Events:"
    echo ""
    echo "Просмотр логов пода (если он запущен):"
    POD=$(kubectl get pods -n microservices-lab -l app=nginx-prometheus-exporter -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    if [ ! -z "$POD" ]; then
        kubectl logs $POD -n microservices-lab
    else
        echo "Под не найден или не запущен"
    fi
fi

echo ""
echo "=========================================="
echo "После загрузки образа выполните:"
echo "  kubectl apply -f manifests/infra/nginx-prometheus-exporter-deployment.yaml -n microservices-lab"
echo "=========================================="


