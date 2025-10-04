# Диагностика проблем с метриками

## Проблема: "No data" в дашбордах Grafana

### Возможные причины:

1. **Сервисы не запущены**
2. **Prometheus не может подключиться к сервисам**
3. **Неправильные названия метрик в дашбордах**
4. **Проблемы с сетью Docker**

## Пошаговая диагностика:

### 1. Проверьте статус сервисов
```bash
docker-compose ps
```

Все сервисы должны быть в состоянии "Up".

### 2. Проверьте доступность метрик напрямую

**AuthService:**
```bash
curl http://localhost:8010/metrics
```

**User Service:**
```bash
curl http://localhost:8070/metrics
```

**App Service:**
```bash
curl http://localhost:8080/metrics
```

**API Gateway:**
```bash
curl http://localhost:4040/metrics
```

### 3. Проверьте Prometheus

Откройте http://localhost:9090 и перейдите в:
- **Status → Targets** - проверьте статус всех targets
- **Graph** - выполните запрос `up` для проверки доступности сервисов

### 4. Проверьте Grafana

Откройте http://localhost:3000 и:
- Перейдите в **Configuration → Data Sources**
- Убедитесь, что Prometheus datasource настроен правильно
- Проверьте подключение к Prometheus

### 5. Используйте Debug дашборд

Откройте дашборд "Debug - All Metrics" для проверки базовых метрик.

## Возможные решения:

### Если сервисы не запускаются:

1. **Проверьте логи:**
```bash
docker-compose logs authservice
docker-compose logs user-service
docker-compose logs app
docker-compose logs api-gateway
```

2. **Пересоберите образы:**
```bash
docker-compose build --no-cache
docker-compose up -d
```

### Если Prometheus не видит сервисы:

1. **Проверьте сеть Docker:**
```bash
docker network ls
docker network inspect servers_app-network
```

2. **Проверьте, что сервисы доступны из Prometheus:**
```bash
docker exec -it prometheus sh
# Внутри контейнера:
wget -qO- http://servers-authservice-1:8010/metrics
wget -qO- http://servers-user-service-1:8070/metrics
wget -qO- http://servers-app-1:8080/metrics
wget -qO- http://api-gateway:4040/metrics
```

### Если метрики есть, но дашборды пустые:

1. **Проверьте названия метрик в Prometheus:**
   - Откройте http://localhost:9090/graph
   - Выполните запрос для просмотра доступных метрик:
     - `{__name__=~".*"}` - все метрики
     - `up` - статус сервисов
     - `http_requests_total` - HTTP метрики
     - `jvm_memory_used_bytes` - JVM метрики

2. **Обновите дашборды с правильными названиями метрик**

## Типичные проблемы:

### 1. Kotlin сервисы не экспортируют метрики
**Решение:** Убедитесь, что зависимости добавлены и MicrometerMetrics установлен правильно.

### 2. Python сервис не экспортирует метрики
**Решение:** Убедитесь, что prometheus-client установлен и middleware настроен.

### 3. .NET сервис не экспортирует метрики
**Решение:** Убедитесь, что Prometheus.NET настроен и UseHttpMetrics() добавлен.

### 4. Сетевые проблемы
**Решение:** Проверьте, что все сервисы находятся в одной Docker сети.

## Команды для быстрой диагностики:

```bash
# Проверка статуса всех сервисов
docker-compose ps

# Проверка логов всех сервисов
docker-compose logs

# Перезапуск всех сервисов
docker-compose restart

# Полная пересборка и запуск
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

## Проверка метрик в Prometheus:

1. Откройте http://localhost:9090
2. Перейдите в "Graph"
3. Выполните запросы:
   - `up` - статус всех сервисов
   - `{__name__=~"http_.*"}` - HTTP метрики
   - `{__name__=~"jvm_.*"}` - JVM метрики
   - `{__name__=~"process_.*"}` - метрики процессов
