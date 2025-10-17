# Правильные метрики для Kotlin сервисов

## Проблема была решена!

После анализа реального вывода `curl http://localhost:8080/metrics` выяснилось, что Ktor с Micrometer экспортирует метрики с префиксом `ktor_http_server_requests_*`, а не `http_server_requests_*`.

## Реальные метрики Ktor + Micrometer:

### **HTTP метрики:**
- `ktor_http_server_requests_seconds_count` - количество HTTP запросов
- `ktor_http_server_requests_seconds_sum` - суммарное время запросов  
- `ktor_http_server_requests_seconds` - квантили времени (0.5, 0.9, 0.95, 0.99)
- `ktor_http_server_requests_active` - активные запросы
- `ktor_http_server_requests_seconds_max` - максимальное время запроса

### **JVM метрики:**
- `jvm_memory_used_bytes{area="heap"}` - использование heap памяти
- `jvm_memory_used_bytes{area="nonheap"}` - использование non-heap памяти
- `jvm_memory_max_bytes{area="heap"}` - максимальная heap память
- `jvm_threads_live_threads` - количество живых потоков
- `jvm_threads_daemon_threads` - количество daemon потоков
- `jvm_gc_pause_seconds_count` - количество сборок мусора
- `jvm_gc_pause_seconds_sum` - суммарное время сборки мусора

### **Метрики процесса:**
- `process_cpu_usage` - использование CPU
- `process_cpu_time_ns_total` - общее время CPU
- `process_files_open_files` - количество открытых файлов
- `system_cpu_count` - количество CPU
- `system_load_average_1m` - средняя нагрузка за 1 минуту

## Исправленные дашборды:

### 1. **User Service Overview** - обновлен с правильными метриками
### 2. **App Service Overview** - обновлен с правильными метриками  
### 3. **Kotlin Services - Fixed Metrics** - новый дашборд с правильными метриками
### 4. **Microservices Overview** - обновлен общий дашборд

## Правильные PromQL запросы:

### **HTTP Requests Rate:**
```promql
sum(rate(ktor_http_server_requests_seconds_count{job="user-service"}[5m]))
```

### **HTTP Latency p95:**
```promql
ktor_http_server_requests_seconds{job="user-service",quantile="0.95"}
```

### **Active Connections:**
```promql
ktor_http_server_requests_active{job="user-service"}
```

### **Memory Usage:**
```promql
jvm_memory_used_bytes{job="user-service",area="heap"}
```

### **JVM Threads:**
```promql
jvm_threads_live_threads{job="user-service"}
```

### **GC Time:**
```promql
sum(rate(jvm_gc_pause_seconds_sum{job="user-service"}[5m]))
```

## Тестирование:

```bash
# 1. Проверьте метрики
curl http://localhost:8070/metrics | grep ktor_http_server_requests
curl http://localhost:8080/metrics | grep ktor_http_server_requests

# 2. Сделайте тестовые запросы
curl http://localhost:8070/users
curl http://localhost:8080/films

# 3. Проверьте в Prometheus
# Откройте http://localhost:9090/graph
# Выполните: ktor_http_server_requests_seconds_count{job="user-service"}

# 4. Проверьте в Grafana
# Откройте http://localhost:3000
# Найдите дашборд "Kotlin Services - Fixed Metrics"
```

## Результат:

Теперь все метрики должны отображаться корректно в дашбордах Grafana, так как используются правильные названия метрик, которые реально экспортирует Ktor с Micrometer.

**Ключевое отличие:** Ktor использует префикс `ktor_http_server_requests_*` вместо стандартного `http_server_requests_*`.


