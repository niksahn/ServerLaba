@echo off
REM Скрипт для загрузки образов в minikube
REM Использование: load-images-to-minikube.bat

echo === Loading images in minikube ===

echo Loading AuthService...
minikube imagLoadinge load servers-authservice:latest
if errorlevel 1 (
    echo Попытка альтернативного способа загрузки...
    docker save servers-authservice:latest | minikube image load
)

echo Loading UserService...
minikube image load servers-user-service:latest
if errorlevel 1 (
    echo Попытка альтернативного способа загрузки...
    docker save servers-user-service:latest | minikube image load
)

echo Loading AppService...
minikube image load servers-app:latest
if errorlevel 1 (
    echo Попытка альтернативного способа загрузки...
    docker save servers-app:latest | minikube image load
)

echo Loading API Gateway...
minikube image load servers-api-gateway:latest
if errorlevel 1 (
    echo Попытка альтернативного способа загрузки...
    docker save api-gateway:latest | minikube image load
)

echo Loading Prolog Server...
minikube image load servers-prolog-server:latest
if errorlevel 1 (
    echo Попытка альтернативного способа загрузки...
    docker save prolog-server:latest | minikube image load
)

echo Loading grafana...

minikube image load grafana/grafana:latest
echo === Все образы загружены в minikube ===

