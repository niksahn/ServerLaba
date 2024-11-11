# Используем образ с JDK для сборки
FROM openjdk:17-jdk AS build

# Устанавливаем рабочую директорию
 WORKDIR user-service

# Копируем все необходимые файлы для сборки
COPY gradlew ./
COPY gradle ./gradle
COPY settings.gradle.kts ./
COPY build.gradle.kts ./
COPY gradle.properties ./
COPY src ./src

# Устанавливаем права на выполнение скрипта gradlew
RUN chmod +x ./gradlew

# Выполняем сборку проекта с Gradle
RUN ./gradlew build -x test

# Используем более легкий образ JRE для запуска
FROM openjdk:17-jdk-slim

# Устанавливаем рабочую директорию
 WORKDIR user-service

# Копируем собранный .jar файл из предыдущего контейнера
COPY --from=build user-service/build/libs/com.brigada.laba.userService-all.jar app.jar

# Запускаем приложение
CMD ["java", "-jar", "app.jar"]