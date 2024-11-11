from enum import Enum
from typing import List

import requests
from fastapi import Body, APIRouter
import httpx
from fastapi import HTTPException
from fastapi import status

access_levels = ['USER', 'MODERATOR', 'ADMIN']

service = "http://localhost:8010"


class UserRole(Enum):
    ADMIN = "ADMIN"
    USER = "USER"
    MODERATOR = "MODERATOR"


userAccess = [UserRole.USER, UserRole.MODERATOR, UserRole.ADMIN]

adminAccess = [UserRole.ADMIN]

moderatorAccess = [UserRole.ADMIN, UserRole.MODERATOR]


async def authorization(roles: [List[str]], token: str = None):
    async with httpx.AsyncClient() as client:
        try:
            # Отправляем токен и требуемые роли на сервис авторизации
            response = await client.post(
                "http://localhost:8010/auth/identify",
                json={"accessToken": token, "role": roles}  # Отправляем роли, если они заданы
            )
            print(response)
            if response.status_code == status.HTTP_200_OK:
                return True  # Токен действителен, и пользователь имеет нужные роли
            elif response.status_code == status.HTTP_400_BAD_REQUEST:
                raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Unauthorized")

            elif response.status_code == status.HTTP_401_UNAUTHORIZED:
                raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Unauthorized")
            elif response.status_code == status.HTTP_403_FORBIDDEN:
                raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Forbidden")
        except httpx.RequestError as e:
            raise HTTPException(status_code=status.HTTP_503_SERVICE_UNAVAILABLE, detail="Auth service unavailable")


router = APIRouter()


@router.post("/auth/refresh", tags=["auth"])
async def refresh_token(data: dict):
    # Работа без проверки токена
    response = requests.post(f"{service}/auth/refresh", json=data)
    return response.json()


@router.post("/auth/identify", tags=["auth"])
async def identify_user(data: dict):
    response = requests.post(f"{service}/auth/identify", json=data)
    return response.json()


@router.post("/auth", tags=["auth"])
async def authenticate_user(data: dict):
    response = requests.post(f"{service}/auth", json=data)
    return response.json()


@router.post("/auth/logout", tags=["auth"])
async def logout_user(data: dict):
    response = requests.post(f"{service}/auth/logout", json=data)
    return response.json()
