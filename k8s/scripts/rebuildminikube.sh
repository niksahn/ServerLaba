# Остановить кластер
minikube stop

# Удалить кластер
minikube delete

# Создать кластер с несколькими нодами и правильным CNI
minikube start --nodes=2 --network-plugin=cni --cni=calico
