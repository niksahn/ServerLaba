import requests
from fastapi import APIRouter, Header, Depends

from auth import authorization, userAccess, moderatorAccess, authorize_user, get_token
from pydantic import BaseModel
from reqHead import forward_request

service = "http://servers-app-1:8080"
router = APIRouter()


# service = "http://localhost:8080"


class FilmUpdateModel(BaseModel):
    id: str
    genre: str
    description: str
    name: str
    link: str


class FilmAddModel(BaseModel):
    genre: str
    description: str
    name: str
    link: str


class FilmAddModel1(BaseModel):
    genre: str
    description: str
    name: str
    link: str
    userId: str


class RecommendationRequestModel(BaseModel):
    users: list[str]
    selectedFilmsCount: int


@router.get("/films", tags=["films"])
async def get_films(_: None = Depends(lambda token=Depends(get_token): authorize_user(userAccess, token))):
    return await forward_request(
        method="GET",
        url=f"{service}/films"
    )


# Получение информации о фильме по ID
@router.get("/film/{id}", tags=["films"])
async def get_film(id: str, _: None = Depends(lambda token=Depends(get_token): authorize_user(userAccess, token))):
    return await forward_request(
        method="GET",
        url=f"{service}/film/{id}"
    )


# Удаление всех фильмов
@router.delete("/films", tags=["films"])
async def delete_all_films(_: None = Depends(lambda token=Depends(get_token): authorize_user(userAccess, token))):
    return await forward_request(
        method="DELETE",
        url=f"{service}/films"
    )


# Удаление фильма по ID
@router.delete("/film/{id}", tags=["films"])
async def delete_film(id: str,
                      _: None = Depends(lambda token=Depends(get_token): authorize_user(moderatorAccess, token))):
    return await forward_request(
        method="DELETE",
        url=f"{service}/film/{id}"
    )


# Обновление информации о фильме
@router.post("/film/update", tags=["films"])
async def update_film(
        film_data: FilmUpdateModel,
        _: None = Depends(lambda token=Depends(get_token): authorize_user(moderatorAccess, token))
):
    return await forward_request(
        method="POST",
        url=f"{service}/film/update",
        json_data=film_data.dict()
    )


# Добавление нового фильма
@router.post("/film/add", tags=["films"])
async def add_film(film_data: FilmAddModel,
                   auth=Depends(lambda token=Depends(get_token): authorize_user(moderatorAccess, token))):
    return await forward_request(
        method="POST",
        url=f"{service}/film/add",
        json_data=FilmAddModel1(genre=film_data.genre,
                                description=film_data.description,
                                name=film_data.name,
                                link=film_data.link,
                                userId=auth["userName"]
                                ).dict()
    )


# Получение рекомендаций для пользователя
@router.get("/recommendations/{user}", tags=["recommendations"])
async def get_recommendations_for_user(
        user: str,
        _: None = Depends(lambda token=Depends(get_token): authorize_user(moderatorAccess, token))):
    return await forward_request(
        method="GET",
        url=f"{service}/recommendations/{user}"
    )


# Добавление запроса на рекомендации
@router.post("/recommendations/addRequest", tags=["recommendations"])
async def add_recommendation_request(
        request_data: RecommendationRequestModel,
        _: None = Depends(lambda token=Depends(get_token): authorize_user(userAccess, token))
):
    return await forward_request(
        method="POST",
        url=f"{service}/recommendations/addRequest",
        json_data=request_data.dict()
    )
