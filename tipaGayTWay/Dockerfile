# Используем официальный Python образ в качестве базового
FROM python:3.12-slim

# Установка рабочей директории внутри контейнера
WORKDIR /app

RUN apt-get update \
    && apt-get install -y --no-install-recommends gcc libssl-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Копирование requirements.txt в контейнер
COPY requirements.txt .

# Установка зависимостей Python
RUN pip install --no-cache-dir -r requirements.txt

# Копируем содержимое каталога проекта в контейнер
COPY . .

# Открываем порт для доступа к контейнеру
EXPOSE 4040

# Команда запуска FastAPI с помощью Uvicorn
CMD ["bash","sonar.bash"]
CMD ["python","app/main.py"]