# Дашборд Nginx Load Balancer - Распределение по подам

## Описание

Этот дашборд предоставляет полную картину работы Nginx как балансировщика нагрузки в Kubernetes, включая:

### 📊 Основные возможности

1. **Общая статистика Nginx**
   - Запросы в секунду (RPS)
   - Общее количество запросов за час
   - Среднее время ответа
   - Распределение кодов ответов (круговая диаграмма)

2. **Распределение запросов по подам** (круговые диаграммы)
   - App Service - показывает процент запросов к каждому поду
   - User Service - показывает процент запросов к каждому поду
   - Auth Service - показывает процент запросов к каждому поду

3. **Детальная статистика по сервисам**
   - RPS по каждому поду (временные графики)
   - Время ответа по каждому поду (временные графики)

4. **Нагрузка на поды**
   - CPU Usage для каждого сервиса
   - Memory Usage для каждого сервиса

## 🚀 Установка

### Шаг 1: Применить обновленные конфигурации

Сначала нужно применить обновленные конфигурации Nginx и Telegraf:

```bash
# Применить обновленную конфигурацию Nginx
kubectl apply -f k8s/manifests/configs/nginx-configmap.yaml

# Применить обновленную конфигурацию Telegraf
kubectl apply -f k8s/manifests/configs/telegraf-nginx-configmap.yaml

# Перезапустить Nginx для применения изменений
kubectl rollout restart deployment/nginx -n microservices-lab

# Дождаться готовности
kubectl rollout status deployment/nginx -n microservices-lab
```

### Шаг 2: Импортировать дашборд в Grafana

#### Вариант A: Через ConfigMap (рекомендуется)

1. Обновите ConfigMap с дашбордами:

```bash
# Создать или обновить ConfigMap с дашбордом
kubectl create configmap grafana-dashboard-nginx-lb \
  --from-file=nginx-load-balancer-pods.json=k8s/dashboards/nginx-load-balancer-pods.json \
  -n microservices-lab \
  --dry-run=client -o yaml | kubectl apply -f -

# Добавить label для автоматического обнаружения
kubectl label configmap grafana-dashboard-nginx-lb \
  grafana_dashboard=1 \
  -n microservices-lab
```

2. Перезапустите Grafana:

```bash
kubectl rollout restart deployment/grafana -n microservices-lab
```

#### Вариант B: Через UI Grafana

1. Откройте Grafana в браузере
2. Перейдите в **Dashboards** → **Import**
3. Загрузите файл `k8s/dashboards/nginx-load-balancer-pods.json`
4. Выберите Prometheus как источник данных
5. Нажмите **Import**

### Шаг 3: Проверка метрик

Убедитесь, что метрики собираются корректно:

```bash
# Проверить, что Telegraf работает
kubectl logs -n microservices-lab deployment/nginx -c telegraf --tail=50

# Проверить метрики напрямую
kubectl port-forward -n microservices-lab svc/nginx 9273:9273

# В другом терминале
curl http://localhost:9273/metrics | grep nginxlog
```

Вы должны увидеть метрики с полями `upstream_addr` и `upstream_status`.

## 📈 Как использовать дашборд

### Круговые диаграммы распределения

Круговые диаграммы показывают процентное распределение запросов между подами за последние 5 минут:

- **Зеленый сектор** - servers-app-1:8080 (или соответствующий под)
- **Синий сектор** - servers-app-2:8080
- **Оранжевый сектор** - servers-app-3:8080

Если балансировка работает корректно (Round Robin), вы должны увидеть примерно равное распределение (33%/33%/33%).

### Временные графики

Графики RPS и времени ответа показывают динамику нагрузки на каждый под:

- Если один под получает больше запросов, это может указывать на проблемы с балансировкой
- Если время ответа одного пода значительно выше, это может указывать на проблемы с производительностью

### Метрики нагрузки

Графики CPU и Memory помогают понять, как нагрузка влияет на ресурсы:

- Сравните нагрузку CPU/Memory с количеством запросов
- Если CPU высокий при низком RPS, возможно, есть проблемы с производительностью кода

## 🔧 Настройка алгоритмов балансировки

Для тестирования различных алгоритмов балансировки используйте скрипт:

```bash
# Переключиться на Least Connections
./k8s/tools/switch-nginx-algorithm.sh least-connections

# Переключиться на IP Hash
./k8s/tools/switch-nginx-algorithm.sh ip-hash

# Переключиться на Round Robin (по умолчанию)
./k8s/tools/switch-nginx-algorithm.sh round-robin
```

После переключения наблюдайте за изменениями в круговых диаграммах!

## 🐛 Устранение неполадок

### Метрики не отображаются

1. Проверьте, что Telegraf работает:
```bash
kubectl logs -n microservices-lab deployment/nginx -c telegraf
```

2. Проверьте формат логов Nginx:
```bash
kubectl exec -n microservices-lab deployment/nginx -c nginx -- tail -f /var/log/nginx/access.log
```

Вы должны увидеть строки с `upstream_addr=` и `upstream_status=`.

3. Проверьте, что Prometheus собирает метрики:
```bash
# Port-forward Prometheus
kubectl port-forward -n microservices-lab svc/prometheus 9090:9090

# Откройте http://localhost:9090 и выполните запрос:
nginxlog_resp_bytes_count{upstream_addr!=""}
```

### Круговые диаграммы пустые

Это нормально, если нет трафика! Сгенерируйте нагрузку:

```bash
# Запустить нагрузочное тестирование
kubectl run -it --rm load-test --image=busybox --restart=Never -- sh -c \
  "while true; do wget -q -O- http://nginx/app-service/health; sleep 0.1; done"
```

### Неравномерное распределение

Если вы видите неравномерное распределение при использовании Round Robin:

1. Проверьте, что все поды работают:
```bash
kubectl get pods -n microservices-lab | grep servers-app
```

2. Проверьте конфигурацию Nginx:
```bash
kubectl get configmap nginx-config -n microservices-lab -o yaml
```

3. Убедитесь, что используется правильный алгоритм балансировки

## 📝 Технические детали

### Метрики Telegraf

Telegraf парсит логи Nginx и экспортирует следующие метрики:

- `nginxlog_resp_bytes_count` - количество запросов (с метками `upstream_addr`, `resp_code`, `request`)
- `nginxlog_request_time` - время обработки запроса
- `nginxlog_resp_bytes` - размер ответа в байтах

### Метрики Kubernetes (cAdvisor)

Для метрик нагрузки используются метрики cAdvisor:

- `container_cpu_usage_seconds_total` - использование CPU
- `container_memory_usage_bytes` - использование памяти

### Важные метки

- `upstream_addr` - адрес upstream сервера (например, `servers-app-1:8080`)
- `upstream_status` - статус ответа от upstream
- `resp_code` - HTTP код ответа
- `request` - HTTP запрос (метод и путь)
- `pod` - имя пода Kubernetes

## 🎯 Рекомендации

1. **Мониторинг в реальном времени**: Установите автообновление дашборда на 10-30 секунд
2. **Алерты**: Настройте алерты на неравномерное распределение (>50% на один под)
3. **Исторические данные**: Используйте временной диапазон 1-24 часа для анализа трендов
4. **Нагрузочное тестирование**: Используйте скрипт `compare-algorithms.sh` для сравнения алгоритмов

## 📚 Дополнительная информация

- [Документация Nginx по балансировке нагрузки](http://nginx.org/en/docs/http/load_balancing.html)
- [Telegraf Grok Parser](https://github.com/influxdata/telegraf/tree/master/plugins/parsers/grok)
- [Prometheus Query Examples](https://prometheus.io/docs/prometheus/latest/querying/examples/)
