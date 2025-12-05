# Быстрый старт - Дашборд Nginx Load Balancer

## ✅ Что это дает?

Этот дашборд позволяет:

1. **Видеть распределение запросов по подам** - круговые диаграммы показывают, какой процент запросов идет в каждый под для:
   - App Service (servers-app-1, servers-app-2, servers-app-3)
   - User Service (servers-user-service-1, 2, 3)
   - Auth Service (servers-authservice-1, 2, 3)

2. **Мониторить общую нагрузку на Nginx**:
   - Запросы в секунду (RPS)
   - Коды ответов (200, 400, 500)
   - Среднее время ответа

3. **Отслеживать нагрузку на каждый под**:
   - CPU Usage
   - Memory Usage
   - RPS по каждому поду
   - Время ответа по каждому поду

## 🚀 Быстрая установка

### Вариант 1: Автоматическая установка (рекомендуется)

```powershell
# Запустить скрипт установки
.\k8s\tools\apply-nginx-lb-dashboard.ps1
```

Скрипт автоматически:
- Применит обновленные конфигурации Nginx и Telegraf
- Перезапустит Nginx
- Создаст ConfigMap с дашбордом
- Перезапустит Grafana

### Вариант 2: Ручная установка

```powershell
# 1. Применить конфигурации
kubectl apply -f k8s\manifests\configs\nginx-configmap.yaml
kubectl apply -f k8s\manifests\configs\telegraf-nginx-configmap.yaml

# 2. Перезапустить Nginx
kubectl rollout restart deployment/nginx -n microservices-lab
kubectl rollout status deployment/nginx -n microservices-lab

# 3. Создать ConfigMap с дашбордом
kubectl create configmap grafana-dashboard-nginx-lb `
  --from-file=nginx-load-balancer-pods.json=k8s\dashboards\nginx-load-balancer-pods.json `
  -n microservices-lab

kubectl label configmap grafana-dashboard-nginx-lb grafana_dashboard=1 -n microservices-lab

# 4. Перезапустить Grafana
kubectl rollout restart deployment/grafana -n microservices-lab
```

## 📊 Открыть дашборд

1. **Открыть Grafana**:
```powershell
kubectl port-forward -n microservices-lab svc/grafana 3000:3000
```

2. **Перейти в браузере**: http://localhost:3000

3. **Найти дашборд**: 
   - Меню → Dashboards → Browse
   - Найти "Nginx Load Balancer - Распределение по подам"

## 🧪 Тестирование

### Генерация нагрузки

Чтобы увидеть данные на дашборде, нужно сгенерировать трафик:

```powershell
# Запустить нагрузочный тест на App Service
kubectl run -it --rm load-test-app --image=busybox --restart=Never -- sh -c "while true; do wget -q -O- http://nginx/app-service/health; sleep 0.1; done"

# Запустить нагрузочный тест на User Service
kubectl run -it --rm load-test-user --image=busybox --restart=Never -- sh -c "while true; do wget -q -O- http://nginx/user-service/health; sleep 0.1; done"

# Запустить нагрузочный тест на Auth Service
kubectl run -it --rm load-test-auth --image=busybox --restart=Never -- sh -c "while true; do wget -q -O- http://nginx/auth-service/health; sleep 0.1; done"
```

### Переключение алгоритмов балансировки

Для тестирования различных алгоритмов:

```powershell
# Round Robin (по умолчанию) - равномерное распределение
.\k8s\tools\switch-nginx-algorithm.sh round-robin

# Least Connections - на сервер с наименьшим количеством соединений
.\k8s\tools\switch-nginx-algorithm.sh least-connections

# IP Hash - один клиент всегда идет на один сервер
.\k8s\tools\switch-nginx-algorithm.sh ip-hash
```

После переключения наблюдайте за изменениями в круговых диаграммах!

## 🔍 Проверка работоспособности

### Проверить метрики Telegraf

```powershell
# Port-forward для доступа к метрикам
kubectl port-forward -n microservices-lab svc/nginx 9273:9273

# В другом терминале проверить метрики
curl http://localhost:9273/metrics | Select-String "nginxlog"
```

Вы должны увидеть метрики с полями `upstream_addr` и `upstream_status`.

### Проверить логи Nginx

```powershell
# Получить имя пода Nginx
$NGINX_POD = kubectl get pods -n microservices-lab -l app=nginx -o jsonpath='{.items[0].metadata.name}'

# Посмотреть логи доступа
kubectl exec -n microservices-lab $NGINX_POD -c nginx -- tail -f /var/log/nginx/access.log
```

Вы должны увидеть строки с `upstream_addr="servers-app-1:8080"`.

### Проверить логи Telegraf

```powershell
# Посмотреть логи Telegraf
kubectl logs -n microservices-lab $NGINX_POD -c telegraf --tail=50
```

Не должно быть ошибок парсинга.

## 📈 Что показывает дашборд

### Круговые диаграммы (Pie Charts)

**Что показывают**: Процентное распределение запросов между подами за последние 5 минут.

**Как интерпретировать**:
- **Round Robin**: Примерно равное распределение (33%/33%/33%)
- **Least Connections**: Распределение зависит от нагрузки на поды
- **IP Hash**: Неравномерное распределение (зависит от IP клиентов)

### Графики RPS (Requests Per Second)

**Что показывают**: Количество запросов в секунду к каждому поду.

**Как интерпретировать**:
- Все линии примерно на одном уровне = равномерная балансировка
- Одна линия значительно выше = этот под получает больше запросов

### Графики времени ответа

**Что показывают**: Среднее время ответа каждого пода.

**Как интерпретировать**:
- Все линии примерно на одном уровне = поды работают одинаково
- Одна линия значительно выше = возможны проблемы с производительностью этого пода

### Графики CPU и Memory

**Что показывают**: Использование ресурсов каждым подом.

**Как интерпретировать**:
- Сравните с RPS - высокий CPU при низком RPS может указывать на проблемы
- Растущая память может указывать на утечки памяти

## ❓ Частые вопросы

### Дашборд пустой, нет данных

**Причина**: Нет трафика к сервисам.

**Решение**: Запустите нагрузочный тест (см. раздел "Генерация нагрузки").

### Метрики не обновляются

**Причина**: Telegraf не парсит логи или Prometheus не собирает метрики.

**Решение**:
1. Проверьте логи Telegraf (см. раздел "Проверка работоспособности")
2. Проверьте формат логов Nginx
3. Перезапустите Nginx: `kubectl rollout restart deployment/nginx -n microservices-lab`

### Круговые диаграммы показывают только один под

**Причина**: Возможно, используется алгоритм IP Hash и все запросы идут с одного IP.

**Решение**: 
1. Проверьте алгоритм балансировки в конфигурации Nginx
2. Попробуйте переключиться на Round Robin
3. Генерируйте трафик с разных источников

### Неравномерное распределение при Round Robin

**Причина**: Возможно, один из подов не работает или не готов.

**Решение**:
1. Проверьте статус подов: `kubectl get pods -n microservices-lab | grep servers-app`
2. Проверьте логи проблемного пода
3. Проверьте readiness/liveness probes

## 📚 Дополнительная документация

Подробная документация: [k8s\docs\NGINX-LOAD-BALANCER-DASHBOARD.md](NGINX-LOAD-BALANCER-DASHBOARD.md)

## 🎯 Следующие шаги

1. ✅ Установить дашборд
2. ✅ Сгенерировать тестовую нагрузку
3. ✅ Проверить распределение запросов
4. ✅ Протестировать разные алгоритмы балансировки
5. ✅ Настроить алерты на неравномерное распределение
6. ✅ Использовать для анализа производительности

Удачи! 🚀
