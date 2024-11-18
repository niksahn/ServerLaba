import requests
from fastapi import APIRouter, Header
from fastapi import HTTPException
from fastapi import status
from pydantic import BaseModel

from reqHead import forward_request


class AuthModel(BaseModel):
    username: str
    password: str


class IdentifyModel(BaseModel):
    accessToken: str
    role: list[str]


class LogoutModel(BaseModel):
    token: str


class RefreshModel(BaseModel):
    refreshToken: str


class DeleteUserModel(BaseModel):
    id: str
    token: str


service = "http://servers-authservice-1:8010"

#service = "http://localhost:8010"
userAccess = ["USER", "MODERATOR", "ADMIN"]

adminAccess = ["ADMIN"]

moderatorAccess = ["MODERATOR", "ADMIN"]


# Функция-зависимость для извлечения токена из заголовка Authorization
def get_token(auth: str = Header(...)):
    if not auth.startswith("Bearer "):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authorization header format. Expected 'Bearer <token>'"
        )
    return auth.split(' ')[1]  # Получаем непосредственно токен


# Определите функцию-зависимость для авторизации
def authorize_user(roles: list, token: str = get_token):
    authorization(roles, auth_token=token)


def authorization(roles: list, auth_token: str = None):
    try:
        # Отправляем токен и требуемые роли на сервис авторизации
        response = requests.post(
            f"{service}/auth/identify",
            json={"accessToken": auth_token, "role": roles}
        )

        # Проверяем статус код
        if response.status_code == status.HTTP_200_OK:
            return True  # Токен действителен, и пользователь имеет нужные роли

        # если статус 400 или больше, выбрасываем соответствующую ошибку
        if response.status_code >= 400:
            raise HTTPException(status_code=response.status_code)

    except requests.RequestException:
        raise HTTPException(status_code=status.HTTP_503_SERVICE_UNAVAILABLE, detail="Auth service unavailable")


router = APIRouter()


# Обновление токена
@router.post("/auth/refresh", tags=["auth"])
async def refresh_token(data: RefreshModel):
    return await forward_request(
        method="POST",
        url=f"{service}/auth/refresh",
        json_data=data.dict()
    )


# Идентификация пользователя
@router.post("/auth/identify", tags=["auth"])
async def identify_user(data: IdentifyModel):
    return await forward_request(
        method="POST",
        url=f"{service}/auth/identify",
        json_data=data.dict()
    )


# Аутентификация пользователя
@router.post("/auth", tags=["auth"])
async def authenticate_user(data: AuthModel):
    return await forward_request(
        method="POST",
        url=f"{service}/auth",
        json_data=data.dict()
    )


# Выход пользователя
@router.post("/auth/logout", tags=["auth"])
async def logout_user(data: LogoutModel):
    return await forward_request(
        method="POST",
        url=f"{service}/auth/logout",
        json_data=data.dict()
    )
