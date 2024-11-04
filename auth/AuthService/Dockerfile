# Используем официальный образ .NET SDK для сборки
FROM mcr.microsoft.com/dotnet/sdk:6.0 AS build
WORKDIR /src

# Копируем только файлы с зависимостями
COPY ./AuthService/*.csproj ./AuthService/
WORKDIR ./AuthService

# Восстановление зависимостей
RUN dotnet restore

# Копируем весь код для сборки проекта
COPY . .
WORKDIR ./AuthService
RUN dotnet publish -c Release -o /app/build

# Используем официальный образ .NET Runtime для запуска
FROM mcr.microsoft.com/dotnet/aspnet:6.0 AS runtime
WORKDIR /app

# Копируем собранные файлы из предыдущего образа
COPY --from=build /app/build .

# Устанавливаем переменные среды для конфигурации
ENV ASPNETCORE_URLS=http://+:8010

# Открываем необходимый порт
EXPOSE 8010

# Задаем команду по умолчанию для запуска
ENTRYPOINT ["dotnet", "AuthService.dll"]