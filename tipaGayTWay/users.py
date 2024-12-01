from fastapi import APIRouter, Depends
from pydantic import BaseModel

from auth import userAccess, adminAccess, authorize_user, get_token
from reqHead import forward_request

service = "http://servers-user-service-1:8070"

router = APIRouter()


class UserUpdateModel(BaseModel):
    id: str
    name: str
    watchedFilms: list


class UserCreateModel(BaseModel):
    name: str
    password: str


class UserCreateModel1(BaseModel):
    name: str
    password: str
    role: str
    watchedFilms: list


class UserFilmsUpdateModel(BaseModel):
    id: str
    watchedFilms: list


# Обновление пользователя
@router.patch("/user", tags=["users"])
async def update_user(
        data: UserUpdateModel,
        _: None = Depends(lambda token=Depends(get_token): authorize_user(adminAccess, token))
):
    return await forward_request(
        method="PATCH",
        url=f"{service}/user",
        json_data=data.dict()
    )


# Создание пользователя
@router.post("/user", tags=["users"])
async def create_user(data: UserCreateModel):
    return await forward_request(
        method="POST",
        url=f"{service}/user",
        json_data=UserCreateModel1(name=data.name, password=data.password, role="USER", watchedFilms=[]).dict()
    )


# Обновление списка фильмов пользователя
@router.post("/user/films", tags=["users"])
async def update_user_films(
        data: UserFilmsUpdateModel,
        _: None = Depends(lambda token=Depends(get_token): authorize_user(userAccess, token))
):
    return await forward_request(
        method="POST",
        url=f"{service}/user/films",
        json_data=data.dict()
    )


# Получение списка пользователей
@router.get("/users", tags=["users"])
async def get_users(
        _: None = Depends(lambda token=Depends(get_token): authorize_user(adminAccess, token))
):
    return await forward_request(
        method="GET",
        url=f"{service}/users"
    )


# Получение информации о пользователе по ID
@router.get("/user/{id}", tags=["users"])
async def get_user_by_id(
        id: str,
        _: None = Depends(lambda token=Depends(get_token): authorize_user(userAccess, token))
):
    return await forward_request(
        method="GET",
        url=f"{service}/user/{id}"
    )
