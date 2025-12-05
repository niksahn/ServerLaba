#!/bin/bash

# Скрипт для сравнения различных алгоритмов балансировки
# Использование: ./compare-algorithms.sh <api-gateway-url> <duration> <concurrent-users>

# Определяем директорию скрипта
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1

# Включаем обработку ошибок, но не прерываем на ошибках в pipe и условных конструкциях
set -o pipefail

API_GATEWAY_URL="${1:-http://localhost:4040}"
DURATION="${2:-30}"
CONCURRENT_USERS="${3:-5}"

NAMESPACE="microservices-lab"
ALGORITHMS=("round-robin" "weighted-round-robin" "least-connections" "ip-hash" "random")

echo "=========================================="
echo "Сравнение алгоритмов балансировки"
echo "=========================================="
echo "API Gateway URL: $API_GATEWAY_URL"
echo "Длительность теста на алгоритм: ${DURATION} секунд"
echo "Количество одновременных пользователей: $CONCURRENT_USERS"
echo "=========================================="
echo ""

# Проверяем наличие kubectl
if ! command -v kubectl >/dev/null 2>&1; then
    echo "Ошибка: kubectl не найден. Установите kubectl и повторите попытку."
    exit 1
fi

# Проверяем наличие скрипта переключения
SWITCH_SCRIPT="$SCRIPT_DIR/switch-nginx-algorithm.sh"
if [ ! -f "$SWITCH_SCRIPT" ]; then
    echo "Ошибка: скрипт $SWITCH_SCRIPT не найден"
    exit 1
fi

# Проверяем наличие скрипта нагрузочного тестирования
LOAD_TEST_PY="$SCRIPT_DIR/load-test.py"
LOAD_TEST_SH="$SCRIPT_DIR/load-test.sh"
if [ ! -f "$LOAD_TEST_PY" ] && [ ! -f "$LOAD_TEST_SH" ]; then
    echo "Ошибка: скрипт нагрузочного тестирования не найден (load-test.py или load-test.sh)"
    exit 1
fi

# Проверяем версию Python, если используется Python скрипт
if [ -f "$LOAD_TEST_PY" ]; then
    if command -v python >/dev/null 2>&1; then
        PYTHON_CMD="python"
        # Проверяем версию Python
        PYTHON_VERSION=$($PYTHON_CMD --version 2>&1 | awk '{print $2}' | cut -d. -f1,2)
        PYTHON_MAJOR=$(echo "$PYTHON_VERSION" | cut -d. -f1)
        if [ "$PYTHON_MAJOR" -lt 3 ]; then
            echo "Ошибка: требуется Python 3 или выше. Найден Python $PYTHON_VERSION"
            exit 1
        fi
    elif command -v python3 >/dev/null 2>&1; then
        PYTHON_CMD="python3"
    else
        echo "Ошибка: Python не найден. Установите Python 3 и повторите попытку."
        exit 1
    fi
fi

echo "Применение ConfigMaps..."
CONFIGMAP_COUNT=0
shopt -s nullglob  # Если файлы не найдены, вернуть пустой список вместо паттерна
for f in "$SCRIPT_DIR"/../manifests/configs/nginx-config-*.yaml; do
    if [ -f "$f" ]; then
        kubectl apply -f "$f" || true  # Игнорируем ошибки kubectl (например, если уже применен)
        CONFIGMAP_COUNT=$((CONFIGMAP_COUNT + 1))
    fi
done
shopt -u nullglob  # Отключаем nullglob обратно

if [ "$CONFIGMAP_COUNT" -eq 0 ]; then
    echo "Предупреждение: ConfigMap файлы не найдены в $SCRIPT_DIR"
else
    echo "ConfigMaps применены ($CONFIGMAP_COUNT файлов)."
fi
echo ""

# Создаем файл для результатов
RESULTS_FILE="$SCRIPT_DIR/../results/load-test-results-$(date +%Y%m%d-%H%M%S).txt"
echo "Результаты сравнения алгоритмов балансировки" > "$RESULTS_FILE"
echo "Дата: $(date)" >> "$RESULTS_FILE"
echo "API Gateway: $API_GATEWAY_URL" >> "$RESULTS_FILE"
echo "Длительность теста: ${DURATION} секунд" >> "$RESULTS_FILE"
echo "Пользователей: $CONCURRENT_USERS" >> "$RESULTS_FILE"
echo "==========================================" >> "$RESULTS_FILE"
echo "" >> "$RESULTS_FILE"

# Тестируем каждый алгоритм
for algorithm in "${ALGORITHMS[@]}"; do
    echo ""
    echo "=========================================="
    echo "Тестирование алгоритма: $algorithm"
    echo "=========================================="
    
    # Переключаем алгоритм
    echo "Переключение на алгоритм: $algorithm..."
    if ! bash "$SWITCH_SCRIPT" "$algorithm"; then
        echo "Ошибка: не удалось переключить алгоритм $algorithm"
        echo "Пропускаем этот алгоритм..."
        continue
    fi
    
    # Ждем стабилизации
    echo "Ожидание стабилизации (10 секунд)..."
    sleep 10
    
    # Запускаем тест
    echo "Запуск нагрузочного тестирования..."
    
    if [ -f "$LOAD_TEST_PY" ] && [ -n "$PYTHON_CMD" ]; then
        if ! $PYTHON_CMD "$LOAD_TEST_PY" "$API_GATEWAY_URL" "$algorithm" "$DURATION" "$CONCURRENT_USERS" 2>&1 | tee -a "$RESULTS_FILE"; then
            echo "Предупреждение: ошибка при выполнении нагрузочного теста для $algorithm" | tee -a "$RESULTS_FILE"
        fi
    elif [ -f "$LOAD_TEST_SH" ]; then
        if ! bash "$LOAD_TEST_SH" "$API_GATEWAY_URL" "$algorithm" "$DURATION" "$CONCURRENT_USERS" 2>&1 | tee -a "$RESULTS_FILE"; then
            echo "Предупреждение: ошибка при выполнении нагрузочного теста для $algorithm" | tee -a "$RESULTS_FILE"
        fi
    else
        echo "Ошибка: не найден скрипт для нагрузочного тестирования"
        exit 1
    fi
    
    echo "" >> "$RESULTS_FILE"
    echo "----------------------------------------" >> "$RESULTS_FILE"
    echo "" >> "$RESULTS_FILE"
    
    # Пауза между тестами
    echo "Пауза перед следующим тестом (5 секунд)..."
    sleep 5
done

echo ""
echo "=========================================="
echo "Сравнение завершено!"
echo "=========================================="
echo "Результаты сохранены в файл: $RESULTS_FILE"
echo ""

# Создаем сводную таблицу результатов
echo "Сводка результатов по алгоритмам:"
echo "=========================================="
echo ""

if command -v grep >/dev/null 2>&1 && command -v awk >/dev/null 2>&1; then
    # Извлекаем ключевые метрики для каждого алгоритма
    echo "Алгоритм          | Успешных | Всего   | RPS     | Среднее время | P95"
    echo "------------------|----------|---------|---------|---------------|--------"
    
    CURRENT_ALGORITHM=""
    while IFS= read -r line; do
        # Ищем строку с алгоритмом
        if echo "$line" | grep -q "Алгоритм балансировки:"; then
            CURRENT_ALGORITHM=$(echo "$line" | sed 's/.*: //' | tr -d ' ')
        fi
        # Ищем успешные запросы
        if echo "$line" | grep -q "Успешных:" && [ -n "$CURRENT_ALGORITHM" ]; then
            SUCCESSFUL=$(echo "$line" | awk -F'[()]' '{print $1}' | awk '{print $2}')
            SUCCESS_RATE=$(echo "$line" | awk -F'[()]' '{print $2}' | tr -d '%')
        fi
        # Ищем всего запросов
        if echo "$line" | grep -q "Всего запросов:" && [ -n "$CURRENT_ALGORITHM" ]; then
            TOTAL=$(echo "$line" | awk '{print $3}')
        fi
        # Ищем RPS
        if echo "$line" | grep -q "RPS" && [ -n "$CURRENT_ALGORITHM" ]; then
            RPS=$(echo "$line" | awk '{print $3}')
        fi
        # Ищем среднее время
        if echo "$line" | grep -q "Среднее:" && [ -n "$CURRENT_ALGORITHM" ]; then
            AVG_TIME=$(echo "$line" | awk '{print $2}')
        fi
        # Ищем P95
        if echo "$line" | grep -q "P95:" && [ -n "$CURRENT_ALGORITHM" ]; then
            P95=$(echo "$line" | awk '{print $2}')
            # Выводим строку таблицы
            printf "%-17s | %8s | %7s | %7s | %13s | %s\n" \
                "$CURRENT_ALGORITHM" "$SUCCESSFUL" "$TOTAL" "$RPS" "$AVG_TIME" "$P95"
            # Сбрасываем переменные
            CURRENT_ALGORITHM=""
            SUCCESSFUL=""
            TOTAL=""
            RPS=""
            AVG_TIME=""
            P95=""
        fi
    done < "$RESULTS_FILE"
    
    echo ""
    echo "----------------------------------------"
    echo ""
fi

echo "Детальная информация:"
echo "----------------------------------------"
if command -v grep >/dev/null 2>&1; then
    # Показываем краткую сводку по каждому алгоритму
    ALGORITHM_COUNT=0
    while IFS= read -r line; do
        if echo "$line" | grep -q "Результаты нагрузочного тестирования"; then
            if [ "$ALGORITHM_COUNT" -gt 0 ]; then
                echo ""
            fi
            ALGORITHM_COUNT=$((ALGORITHM_COUNT + 1))
        fi
        if echo "$line" | grep -qE "(Алгоритм балансировки:|Успешных:|Всего запросов:|RPS|Среднее:|P95:|P99:)" && [ "$ALGORITHM_COUNT" -gt 0 ]; then
            echo "$line"
        fi
    done < "$RESULTS_FILE" | head -40
    
    if [ "$ALGORITHM_COUNT" -eq 0 ]; then
        echo "Не удалось извлечь детальную информацию из результатов"
        echo "Проверьте файл: $RESULTS_FILE"
    fi
else
    echo "Детали в файле $RESULTS_FILE"
fi

echo ""
echo "=========================================="
echo "Для просмотра полных результатов откройте файл: $RESULTS_FILE"
echo "=========================================="

