import requests
from fastapi.responses import Response
from fastapi import HTTPException


async def forward_request(method: str, url: str, json_data: dict = None, headers: dict = None):
    try:
        # Совершаем HTTP-запрос с передачей необходимых параметров
        response = requests.request(method, url, json=json_data, headers=headers)

        # Формируем и возвращаем ответ с тем же содержимым и статусом, что и от внутреннего сервиса
        return Response(content=response.content, status_code=response.status_code,
                        media_type=response.headers.get('Content-Type'))

    except requests.exceptions.RequestException as e:
        # Обрабатываем ошибки, если запрос не удался
        raise HTTPException(status_code=500, detail="Internal server error.")
