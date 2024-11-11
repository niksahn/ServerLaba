from auth import authorization, userAccess, adminAccess, moderatorAccess
from pydantic import BaseModel
from fastapi import APIRouter, Header
import requests
from pydantic import BaseModel

service = "http://servers-user-service-1:8070"

router = APIRouter()


class UserUpdateModel(BaseModel):
    id: str
    name: str
    watchedFilms: list


class UserCreateModel(BaseModel):
    name: str
    watchedFilms: list
    role: str
    password: str


class UserFilmsUpdateModel(BaseModel):
    id: str
    watchedFilms: list


@router.patch("/user", tags=["users"])
async def update_user(data: UserUpdateModel, token: str = Header(None)):
    # Проверка, что пользователь имеет доступ на редактирование
    await authorization(adminAccess, token=token)
    response = requests.patch(f"{service}/user", json=data.dict())
    return response.json()


@router.post("/user", tags=["users"])
async def create_user(data: UserCreateModel, token: str = Header(None)):
    # Создание пользователя может требовать доступ администратора
    await authorization(userAccess, token=token)
    response = requests.post(f"{service}/user", json=data.dict())
    return response.json()


@router.post("/user/films", tags=["users"])
async def update_user_films(data: UserFilmsUpdateModel, token: str = Header(None)):
    await authorization(userAccess, token=token)
    response = requests.post(f"{service}/user/films", json=data.dict())
    return response.json()


@router.get("/users", tags=["users"])
async def get_users(token: str = Header(None)):
    await authorization(adminAccess, token=token)
    response = requests.get(f"{service}/users")
    return response.json()


@router.get("/user/{id}", tags=["users"])
async def get_user_by_id(id: str, token: str = Header(None)):
    await authorization(userAccess, token=token)
    response = requests.get(f"{service}/user/{id}")
    return response.json()
