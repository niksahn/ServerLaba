# Используем официальный образ SWI-Prolog
FROM swipl:latest

# Устанавливаем рабочую директорию
WORKDIR /app

# Копируем серверный файл
COPY server.pl /app/
COPY redis.pl /app/

# Устанавливаем рабочую директорию для контейнера
WORKDIR /app

# Открываем порт для общения с сервером
EXPOSE 8090

# Запускаем сервер при старте контейнера
CMD ["swipl", "server.pl"]
