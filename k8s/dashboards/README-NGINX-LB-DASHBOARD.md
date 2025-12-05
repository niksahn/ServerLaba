# 📊 Дашборд Nginx Load Balancer - Распределение запросов по подам

![Dashboard Preview](../../.gemini/antigravity/brain/9d5c1410-daee-48d7-8445-d02883e94ecd/nginx_dashboard_preview_1764269491842.png)

## 🎯 Основная цель

Этот дашборд создан специально для визуализации **распределения запросов по подам** в Kubernetes при использовании Nginx как балансировщика нагрузки.

### ✅ Что можно увидеть

1. **Круговые диаграммы распределения** - показывают процент запросов к каждому поду для:
   - App Service (servers-app-1, servers-app-2, servers-app-3)
   - User Service (servers-user-service-1, 2, 3)
   - Auth Service (servers-authservice-1, 2, 3)

2. **Общие метрики Nginx**:
   - Запросы в секунду (RPS)
   - Общее количество запросов
   - Среднее время ответа
   - Распределение HTTP кодов ответов

3. **Детальная статистика по каждому сервису**:
   - RPS по каждому поду (временные графики)
   - Время ответа по каждому поду
   - CPU и Memory usage для каждого пода

## 🚀 Быстрый старт

### Автоматическая установка (Windows)

```powershell
.\k8s\tools\apply-nginx-lb-dashboard.ps1
```

### Автоматическая установка (Linux/Mac)

```bash
./k8s/tools/apply-nginx-lb-dashboard.sh
```

### Открыть дашборд

```powershell
# 1. Port-forward Grafana
kubectl port-forward -n microservices-lab svc/grafana 3000:3000

# 2. Открыть в браузере
# http://localhost:3000

# 3. Найти дашборд
# Dashboards → Browse → "Nginx Load Balancer - Распределение по подам"
```

## 📖 Документация

- **Быстрый старт (RU)**: [NGINX-DASHBOARD-QUICKSTART-RU.md](NGINX-DASHBOARD-QUICKSTART-RU.md)
- **Полная документация**: [NGINX-LOAD-BALANCER-DASHBOARD.md](NGINX-LOAD-BALANCER-DASHBOARD.md)

## 🧪 Тестирование

### Генерация нагрузки

```powershell
# App Service
kubectl run -it --rm load-test-app --image=busybox --restart=Never -- sh -c "while true; do wget -q -O- http://nginx/app-service/health; sleep 0.1; done"
```

### Переключение алгоритмов балансировки

```bash
# Round Robin (равномерное распределение)
./k8s/tools/switch-nginx-algorithm.sh round-robin

# Least Connections
./k8s/tools/switch-nginx-algorithm.sh least-connections

# IP Hash
./k8s/tools/switch-nginx-algorithm.sh ip-hash
```

## 📊 Структура дашборда

### Секция 1: Общая статистика Nginx
- **RPS** - текущее количество запросов в секунду
- **Total Requests** - общее количество запросов за час
- **Avg Response Time** - среднее время ответа
- **Status Codes** - круговая диаграмма с кодами ответов

### Секция 2: Распределение запросов по подам (Круговые диаграммы)
Три круговые диаграммы показывают процентное распределение запросов:
- **App Service** - распределение между servers-app-1, 2, 3
- **User Service** - распределение между servers-user-service-1, 2, 3
- **Auth Service** - распределение между servers-authservice-1, 2, 3

**Интерпретация**:
- Round Robin: примерно 33%/33%/33%
- Least Connections: зависит от нагрузки
- IP Hash: неравномерное (зависит от IP клиентов)

### Секция 3: Детальная статистика по сервисам
Для каждого сервиса (App, User, Auth):
- **RPS по подам** - график запросов в секунду для каждого пода
- **Response Time по подам** - график времени ответа для каждого пода

### Секция 4: Нагрузка на поды
Для каждого сервиса:
- **CPU Usage** - использование процессора каждым подом
- **Memory Usage** - использование памяти каждым подом

## 🔧 Технические детали

### Метрики

Дашборд использует метрики из двух источников:

1. **Telegraf** (парсинг логов Nginx):
   - `nginxlog_resp_bytes_count` - счетчик запросов с метками `upstream_addr`, `resp_code`, `request`
   - `nginxlog_request_time` - время обработки запроса
   - `nginxlog_resp_bytes` - размер ответа

2. **Kubernetes cAdvisor**:
   - `container_cpu_usage_seconds_total` - использование CPU
   - `container_memory_usage_bytes` - использование памяти

### Важные метки

- `upstream_addr` - адрес upstream сервера (например, `servers-app-1:8080`)
- `upstream_status` - статус ответа от upstream
- `resp_code` - HTTP код ответа
- `request` - HTTP запрос (используется для фильтрации по сервису)
- `pod` - имя пода Kubernetes

### Запросы Prometheus

Примеры запросов, используемых в дашборде:

```promql
# Распределение запросов по подам для App Service
sum by (upstream_addr) (increase(nginxlog_resp_bytes_count{request=~".*app-service.*"}[5m]))

# RPS по подам
rate(nginxlog_resp_bytes_count{request=~".*app-service.*", upstream_addr=~".*"}[5m])

# CPU usage подов
rate(container_cpu_usage_seconds_total{namespace="microservices-lab", pod=~"servers-app-.*"}[5m])
```

## 🐛 Устранение неполадок

### Дашборд пустой

**Проблема**: Нет данных на дашборде.

**Решение**:
1. Убедитесь, что есть трафик к сервисам (запустите нагрузочный тест)
2. Проверьте метрики Telegraf: `kubectl port-forward -n microservices-lab svc/nginx 9273:9273`
3. Проверьте логи Telegraf: `kubectl logs -n microservices-lab deployment/nginx -c telegraf`

### Метрики не обновляются

**Проблема**: Данные устаревшие или не обновляются.

**Решение**:
1. Проверьте, что Nginx перезапущен после обновления конфигурации
2. Проверьте формат логов: `kubectl exec -n microservices-lab deployment/nginx -c nginx -- tail /var/log/nginx/access.log`
3. Убедитесь, что в логах есть поля `upstream_addr=` и `upstream_status=`

### Неравномерное распределение при Round Robin

**Проблема**: Один под получает больше запросов, чем другие.

**Решение**:
1. Проверьте статус подов: `kubectl get pods -n microservices-lab`
2. Убедитесь, что все поды в состоянии Ready
3. Проверьте конфигурацию Nginx: `kubectl get configmap nginx-config -n microservices-lab -o yaml`

## 📝 Изменения в конфигурации

Для работы дашборда были внесены следующие изменения:

### 1. Nginx ConfigMap (`nginx-configmap.yaml`)

Обновлен формат логов для включения информации об upstream:

```nginx
log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                '$status $body_bytes_sent "$http_referer" '
                '"$http_user_agent" "$http_x_forwarded_for" '
                'upstream_addr="$upstream_addr" upstream_status="$upstream_status" '
                'request_time=$request_time upstream_response_time=$upstream_response_time';
```

### 2. Telegraf ConfigMap (`telegraf-nginx-configmap.yaml`)

Обновлен паттерн Grok для парсинга новых полей:

```toml
grok_patterns = [
  "%{IPORHOST:remote_addr} - %{USER:remote_user} \\[%{HTTPDATE:time_local}\\] \"%{DATA:request}\" %{NUMBER:resp_code} %{NUMBER:resp_bytes} \"%{DATA:referrer}\" \"%{DATA:agent}\" \"%{DATA:forwarded_for}\" upstream_addr=\"%{DATA:upstream_addr}\" upstream_status=\"%{DATA:upstream_status}\" request_time=%{NUMBER:request_time:float} upstream_response_time=%{DATA:upstream_response_time}"
]
```

Добавлены новые метки для экспорта:

```toml
[outputs.prometheus_client.string_as_label]
  upstream_addr = true
  upstream_status = true
```

## 🎯 Примеры использования

### Сценарий 1: Проверка балансировки Round Robin

1. Убедитесь, что используется Round Robin: `kubectl get configmap nginx-config -n microservices-lab -o yaml | grep -A 5 "upstream app-service"`
2. Запустите нагрузочный тест
3. Откройте дашборд и посмотрите на круговую диаграмму App Service
4. Вы должны увидеть примерно равное распределение (33%/33%/33%)

### Сценарий 2: Сравнение алгоритмов балансировки

1. Запустите нагрузочный тест
2. Переключитесь на Round Robin и наблюдайте распределение
3. Переключитесь на Least Connections и сравните
4. Переключитесь на IP Hash и сравните
5. Используйте графики RPS для анализа производительности

### Сценарий 3: Поиск проблем с производительностью

1. Посмотрите на графики времени ответа по подам
2. Если один под значительно медленнее:
   - Проверьте CPU/Memory usage этого пода
   - Проверьте логи пода
   - Возможно, под перегружен или имеет проблемы

## 🔗 Связанные файлы

- **Дашборд**: `k8s/dashboards/nginx-load-balancer-pods.json`
- **Скрипт установки (PowerShell)**: `k8s/tools/apply-nginx-lb-dashboard.ps1`
- **Скрипт установки (Bash)**: `k8s/tools/apply-nginx-lb-dashboard.sh`
- **Конфигурация Nginx**: `k8s/manifests/configs/nginx-configmap.yaml`
- **Конфигурация Telegraf**: `k8s/manifests/configs/telegraf-nginx-configmap.yaml`

## 📚 Дополнительные ресурсы

- [Nginx Load Balancing Documentation](http://nginx.org/en/docs/http/load_balancing.html)
- [Grafana Dashboard Best Practices](https://grafana.com/docs/grafana/latest/dashboards/build-dashboards/best-practices/)
- [Prometheus Query Examples](https://prometheus.io/docs/prometheus/latest/querying/examples/)
- [Telegraf Grok Parser](https://github.com/influxdata/telegraf/tree/master/plugins/parsers/grok)

---

**Автор**: Создано для проекта ServerLaba  
**Версия**: 1.0  
**Дата**: 2025-11-27
