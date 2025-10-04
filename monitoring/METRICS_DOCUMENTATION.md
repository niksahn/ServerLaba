# Документация по метрикам микросервисов

## Обзор

В рамках лабораторной работы №3 были добавлены метрики мониторинга во все микросервисы системы. Система мониторинга построена на базе Prometheus и Grafana.

## Архитектура мониторинга

- **Prometheus** - сбор и хранение метрик
- **Grafana** - визуализация метрик и дашборды
- **Микросервисы** - источники метрик

## Добавленные метрики по сервисам

### 1. AuthService (C# .NET)
**Порт:** 8010  
**Эндпоинт метрик:** `/metrics`

**Добавленные метрики:**
- `http_requests_total` - общее количество HTTP запросов
- `http_request_duration_seconds` - длительность HTTP запросов
- `http_requests_in_flight` - активные соединения
- `process_working_set_bytes` - использование памяти
- `process_start_time_seconds` - время запуска процесса

**Изменения в коде:**
- Уже был настроен в `StartApp.cs` с использованием библиотеки Prometheus.NET
- Добавлен middleware `UseHttpMetrics()`
- Настроен endpoint `/metrics`

### 2. User Service (Kotlin/Ktor)
**Порт:** 8070  
**Эндпоинт метрик:** `/metrics`

**Добавленные метрики:**
- `http_server_requests_seconds_count` - количество HTTP запросов
- `http_server_requests_seconds_sum` - суммарное время запросов
- `http_server_requests_seconds_bucket` - гистограмма времени запросов
- `http_server_requests_seconds_active` - активные запросы
- `jvm_memory_used_bytes` - использование памяти JVM
- `process_start_time_seconds` - время запуска процесса

**Изменения в коде:**
- Добавлены зависимости в `build.gradle.kts`:
  - `io.ktor:ktor-server-metrics-micrometer`
  - `io.micrometer:micrometer-registry-prometheus`
- Настроен `MicrometerMetrics` в `Application.kt`
- Добавлен endpoint `/metrics`

### 3. App Service (Kotlin/Ktor)
**Порт:** 8080  
**Эндпоинт метрик:** `/metrics`

**Добавленные метрики:**
- `http_server_requests_seconds_count` - количество HTTP запросов
- `http_server_requests_seconds_sum` - суммарное время запросов
- `http_server_requests_seconds_bucket` - гистограмма времени запросов
- `http_server_requests_seconds_active` - активные запросы
- `jvm_memory_used_bytes` - использование памяти JVM
- `process_start_time_seconds` - время запуска процесса

**Изменения в коде:**
- Добавлены зависимости в `build.gradle.kts`
- Настроен `MicrometerMetrics` в `Application.kt`
- Добавлен endpoint `/metrics`

### 4. API Gateway (Python/FastAPI)
**Порт:** 4040  
**Эндпоинт метрик:** `/metrics`

**Добавленные метрики:**
- `http_requests_total` - общее количество HTTP запросов
- `http_request_duration_seconds` - длительность HTTP запросов
- `http_requests_in_flight` - активные соединения
- `api_calls_total` - бизнес-метрики API вызовов

**Изменения в коде:**
- Добавлена зависимость `prometheus-client==0.20.0` в `requirements.txt`
- Создан файл `metrics.py` с настройкой метрик
- Добавлен middleware для автоматического сбора метрик
- Настроен endpoint `/metrics`

## Дашборды Grafana

### 1. AuthService Overview
- Uptime процесса
- Rate HTTP запросов
- HTTP Latency p95
- 5xx Errors Rate
- Active Connections
- Memory Usage

### 2. User Service Overview
- Uptime процесса
- Rate HTTP запросов
- HTTP Latency p95
- 5xx Errors Rate
- Active Connections
- Memory Usage (JVM)

### 3. App Service Overview
- Uptime процесса
- Rate HTTP запросов
- HTTP Latency p95
- 5xx Errors Rate
- Active Connections
- Memory Usage (JVM)

### 4. API Gateway Overview
- Uptime процесса
- Rate HTTP запросов
- HTTP Latency p95
- 5xx Errors Rate
- Active Connections
- API Calls by Service

### 5. Microservices Overview (Общий дашборд)
- Total Services
- Services Up/Down
- Total HTTP Requests Rate
- Service Status
- Total Errors Rate
- Memory Usage by Service
- Active Connections

## Конфигурация Prometheus

Обновлен файл `monitoring/prometheus.yml` для сбора метрик со всех сервисов:

```yaml
scrape_configs:
  - job_name: 'authservice'
    metrics_path: /metrics
    static_configs:
      - targets: ['servers-authservice-1:8010']

  - job_name: 'user-service'
    metrics_path: /metrics
    static_configs:
      - targets: ['servers-user-service-1:8070']

  - job_name: 'app-service'
    metrics_path: /metrics
    static_configs:
      - targets: ['servers-app-1:8080']

  - job_name: 'api-gateway'
    metrics_path: /metrics
    static_configs:
      - targets: ['api-gateway:4040']
```

## Как просмотреть метрики в Grafana

1. **Запуск системы:**
   ```bash
   docker-compose up -d
   ```

2. **Доступ к Grafana:**
   - URL: http://localhost:3000
   - Логин: admin
   - Пароль: admin123

3. **Просмотр дашбордов:**
   - Перейдите в раздел "Dashboards"
   - Выберите нужный дашборд:
     - "AuthService Overview"
     - "User Service Overview"
     - "App Service Overview"
     - "API Gateway Overview"
     - "Microservices Overview"

4. **Проверка метрик в Prometheus:**
   - URL: http://localhost:9090
   - Перейдите в раздел "Status" → "Targets" для проверки статуса сбора метрик

## Типы метрик

### Counter (Счетчики)
- `http_requests_total` - общее количество запросов
- `api_calls_total` - бизнес-метрики

### Histogram (Гистограммы)
- `http_request_duration_seconds` - распределение времени ответа
- `http_server_requests_seconds` - метрики Ktor

### Gauge (Измерители)
- `http_requests_in_flight` - активные соединения
- `jvm_memory_used_bytes` - использование памяти
- `process_working_set_bytes` - использование памяти .NET

## Мониторинг производительности

Добавленные метрики позволяют отслеживать:
- **Производительность:** время ответа, throughput
- **Надежность:** количество ошибок, uptime
- **Ресурсы:** использование памяти, активные соединения
- **Бизнес-метрики:** количество API вызовов по сервисам

## Заключение

Система мониторинга полностью настроена и готова к использованию. Все микросервисы оснащены необходимыми метриками для анализа производительности и надежности распределенной системы.
