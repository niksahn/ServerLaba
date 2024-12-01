from random import Random
from time import sleep

import requests

test_user = "123"
test_password = "123"
base_url = "http://localhost:4040"


def user_authorization(password=test_password, login=test_user):
    auth_response = requests.post(
        f"{base_url}/auth",
        json={"username": login, "password": password}
    )
    assert auth_response.status_code == 200
    return auth_response.json().get("accessToken")


def forward_request(method: str, url: str, auth: bool, json_data: dict = None):
    # Добавляем авторизацию в заголовок
    headers = {}
    if auth:
        access_token = user_authorization()
        headers['auth'] = f"Bearer {access_token}"
    # Совершаем HTTP-запрос с передачей необходимых параметров
    response = requests.request(method, url, json=json_data, headers=headers)
    print(f"\nStatus: {response.status_code}, Data Sent: {json_data}")
    assert response.status_code == 200
    return response


def registr():
    return forward_request(
        method="POST",
        url=f"{base_url}/user",
        json_data=dict(name="11", password="11"),
        auth=False
    ).content.decode('utf-8')


def test_regist():
    forward_request(
        method="GET",
        url=f"{base_url}/user/{registr()}",
        auth=True
    )


def addFilm():
    rand = Random().random()
    return forward_request(
        method="POST",
        url=f"{base_url}/film/add",
        auth=True,
        json_data=dict(
            genre="Комедия",
            description=f"Test_{rand}",
            name=f"Test_{rand}",
            link=f"Test_{rand}"
        )
    ).content.decode('utf-8')


def test_add_film():
    forward_request(
        method="GET",
        url=f"{base_url}/film/{addFilm()}",
        auth=True
    )


def test_delete_film():
    response = forward_request(
        method="DELETE",
        url=f"{base_url}/film/{addFilm()}",
        auth=True
    ).content.decode('utf-8')


def test_get_recommendations():
    user_id = registr()
    forward_request(
        method="POST",
        url=f"{base_url}/recommendations/addRequest",
        auth=True,
        json_data=dict(
            users=[user_id], selectedFilmsCount="20"
        )
    )
    sleep(200)
    forward_request(
        method="GET",
        url=f"{base_url}/recommendations/{user_id}",
        auth=True
    )


def test_full_scenario():
    # 1. Зарегистрировать пользователя
    user_id = registr()

    # 2. Аутентифицироваться
    auth_token = user_authorization("11", "11")
    assert auth_token is not None, "Не удалось получить токен аутентификации"

    # 3. Добавить фильм

    film_id = addFilm()

    # 4. Обновить фильм
    updated_film_data = dict(
        id=film_id,
        genre="Комедия",
        description="Test_0",
        name="Test_0",
        link="Test_0"
    )
    update_film_response = forward_request(
        method="POST",
        url=f"{base_url}/film/update",
        auth=True,
        json_data=updated_film_data
    )
    print(update_film_response.content.decode('utf-8'))

    # 5. Получить рекомендации

    forward_request(
        method="POST",
        url=f"{base_url}/recommendations/addRequest",
        auth=True,
        json_data=dict(
            users=[user_id], selectedFilmsCount="20"
        )
    )
    sleep(200)
    forward_request(
        method="GET",
        url=f"{base_url}/recommendations/{user_id}",
        auth=True
    )

    # 6. Удалить фильм
    delete_film_response = forward_request(
        method="DELETE",
        url=f"{base_url}/film/{film_id}",
        auth=True
    )
    print(delete_film_response.content.decode('utf-8'))

    # 7. Проверить отсутствие фильма
    # Пытаемся получить удаленный фильм, ожидается ошибка или пустой ответ
    try:
        get_deleted_film_response = forward_request(
            method="GET",
            url=f"{base_url}/film/{film_id}",
            auth=True
        )
        assert get_deleted_film_response.status_code == 404, "Фильм должен быть недоступен после удаления"
    except AssertionError as e:
        print(f"Ошибка при проверке отсутствия фильма: {e}")

    # 8. Логаут (если требуется, добавьте API для логаута)
    # logout_response = forward_request(
    #     method="POST",
    #     url=f"{base_url}/auth/logout",
    #     auth=True
    # )
    # print(logout_response.content.decode('utf-8'))
