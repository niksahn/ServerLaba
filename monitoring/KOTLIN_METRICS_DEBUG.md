# Диагностика метрик Kotlin сервисов

## Проблема: Пустые метрики в дашбордах

### Причины:
1. **Неправильные названия метрик** - Ktor с Micrometer экспортирует метрики в формате Spring Boot Actuator
2. **Отсутствие HTTP трафика** - метрики создаются только при наличии запросов
3. **Проблемы с конфигурацией Micrometer**

## Пошаговая диагностика:

### 1. Проверьте доступность метрик
```bash
# User Service
curl http://localhost:8070/metrics

# App Service  
curl http://localhost:8080/metrics
```

### 2. Проверьте реальные названия метрик
В выводе curl найдите метрики, начинающиеся с:
- `http_server_requests_seconds_*` - HTTP метрики
- `jvm_memory_*` - JVM метрики
- `jvm_threads_*` - метрики потоков
- `jvm_gc_*` - метрики сборки мусора

### 3. Создайте тестовые запросы
```bash
# Сделайте несколько запросов к сервисам
curl http://localhost:8070/users
curl http://localhost:8080/films

# Проверьте метрики снова
curl http://localhost:8070/metrics | grep http_server_requests
```

### 4. Проверьте в Prometheus
Откройте http://localhost:9090/graph и выполните запросы:
```promql
# Проверьте статус сервисов
up{job="user-service"}
up{job="app-service"}

# Проверьте HTTP метрики
http_server_requests_seconds_count{job="user-service"}

# Проверьте JVM метрики
jvm_memory_used_bytes{job="user-service"}
```

## Правильные метрики для Ktor + Micrometer:

### HTTP метрики:
- `http_server_requests_seconds_count` - количество запросов
- `http_server_requests_seconds_sum` - суммарное время
- `http_server_requests_seconds_bucket` - гистограмма времени
- `http_server_requests_seconds_active` - активные запросы

### JVM метрики:
- `jvm_memory_used_bytes{area="heap"}` - использование heap памяти
- `jvm_memory_used_bytes{area="nonheap"}` - использование non-heap памяти
- `jvm_memory_max_bytes{area="heap"}` - максимальная heap память
- `jvm_threads_live_threads` - количество живых потоков
- `jvm_gc_pause_seconds_total` - время сборки мусора

### Метрики процесса:
- `process_start_time_seconds` - время запуска
- `process_cpu_seconds_total` - использование CPU
- `process_resident_memory_bytes` - использование памяти процесса

## Обновленные дашборды:

### 1. Kotlin Services - Real Metrics
Новый дашборд с правильными метриками для Kotlin сервисов

### 2. Обновленные существующие дашборды
- User Service Overview
- App Service Overview

## Команды для тестирования:

```bash
# 1. Перезапустите сервисы
docker-compose restart user-service app

# 2. Сделайте тестовые запросы
for i in {1..10}; do
  curl http://localhost:8070/users
  curl http://localhost:8080/films
  sleep 1
done

# 3. Проверьте метрики
curl http://localhost:8070/metrics | grep -E "(http_server_requests|jvm_memory)"

# 4. Проверьте в Prometheus
# Откройте http://localhost:9090/graph
# Выполните: http_server_requests_seconds_count{job="user-service"}
```

## Если метрики все еще пустые:

### 1. Проверьте логи сервисов
```bash
docker-compose logs user-service
docker-compose logs app
```

### 2. Проверьте конфигурацию Micrometer
Убедитесь, что в Application.kt правильно настроен:
```kotlin
install(MicrometerMetrics) {
    registry = appMicrometerRegistry
}
```

### 3. Проверьте зависимости
Убедитесь, что в build.gradle.kts добавлены:
```kotlin
implementation("io.ktor:ktor-server-metrics-micrometer:$ktor_version")
implementation("io.micrometer:micrometer-registry-prometheus:1.11.5")
```

## Альтернативное решение:

Если метрики все еще не работают, можно добавить кастомные метрики:

```kotlin
// В Application.kt
val requestCounter = Counter.builder("custom_http_requests_total")
    .description("Total HTTP requests")
    .register(appMicrometerRegistry)

val requestTimer = Timer.builder("custom_http_request_duration_seconds")
    .description("HTTP request duration")
    .register(appMicrometerRegistry)
```

Но сначала попробуйте стандартные метрики Ktor + Micrometer.

