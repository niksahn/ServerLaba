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


def test_user_authorization_failure():
    try:
        user_authorization("wrong_password", "wrong_user")
    except AssertionError:
        print("Authorization failed as expected with incorrect credentials")


def test_registr_duplicate():
    login = "Test_" + str(Random().randint(0, 1000) + Random().random())
    registr_id = forward_request(
        method="POST",
        url=f"{base_url}/user",
        json_data=dict(name=login, password="11"),
        auth=False
    )
    duplicate_user_response = forward_request(
        method="POST",
        url=f"{base_url}/user",
        json_data=dict(name=login, password="11"),
        auth=False,
        check=False
    )
    assert duplicate_user_response.status_code != 200, "Duplicate user registration should fail"


def forward_request(method: str, url: str, auth: bool, json_data: dict = None, check=True):
    # Добавляем авторизацию в заголовок
    headers = {}
    if auth:
        access_token = user_authorization()
        headers['auth'] = f"Bearer {access_token}"
    # Совершаем HTTP-запрос с передачей необходимых параметров
    response = requests.request(method, url, json=json_data, headers=headers)
    print(f"\nStatus: {response.status_code}, Data Sent: {json_data}")
    if check:
        assert response.status_code == 200
    return response


def test_get_non_existing_film():
    non_existing_film_id = "non-existing-film-id"
    response = forward_request(
        method="GET",
        url=f"{base_url}/film/{non_existing_film_id}",
        auth=True,
        check=False
    )
    assert response.status_code == 400, "Request for non-existing film should return 404 status"


def test_delete_non_existing_film():
    film_id = addFilm()
    # Сначала удаляем фильм
    forward_request(
        method="DELETE",
        url=f"{base_url}/film/{film_id}",
        auth=True
    )
    # Пытаемся удалить его снова
    second_deletion_response = forward_request(
        method="DELETE",
        url=f"{base_url}/film/{film_id}",
        auth=True,
        check=False
    )
    assert second_deletion_response.status_code == 400, "Deleting non-existing film should return 404 status"


def test_add_film_with_missing_fields():
    response = forward_request(
        method="POST",
        url=f"{base_url}/film/add",
        auth=True,
        json_data=dict(
            genre="Комедия"
        ),  # Missing other required fields
        check=False
    )
    assert response.status_code == 422, "Adding film with missing fields should return 400 status"


def registr(delete: bool = True):
    login = "Test_" + str(Random().randint(0, 1000) + Random().random())
    req = forward_request(
        method="POST",
        url=f"{base_url}/user",
        json_data=dict(name=login, password="11"),
        auth=False
    ).content.decode('utf-8')
    if delete:
        forward_request(
            method="DELETE",
            url=f"{base_url}/user/{req}",
            auth=True
        )
    return req


def test_regist():
    id = registr(False)
    forward_request(
        method="GET",
        url=f"{base_url}/user/{id}",
        auth=True
    )
    forward_request(
        method="DELETE",
        url=f"{base_url}/user/{id}",
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
    sleep(3)
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
    film_id = addFilm()
    forward_request(
        method="POST",
        url=f"{base_url}/recommendations/addRequest",
        auth=True,
        json_data=dict(
            users=[user_id], selectedFilmsCount="20"
        )
    )
    sleep(2)
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
    # 7. Проверить отсутствие фильма
    # Пытаемся получить удаленный фильм, ожидается ошибка или пустой ответ
    get_deleted_film_response = forward_request(
        method="GET",
        url=f"{base_url}/film/{film_id}",
        auth=True,
        check=False
    )
    assert get_deleted_film_response.status_code == 400, "Фильм должен быть недоступен после удаления"
