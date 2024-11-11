import requests
from fastapi import APIRouter, Header

from auth import authorization, userAccess, moderatorAccess

service = "http://localhost:8080"
router = APIRouter()


# Маршруты для фильмов
@router.get("/films", tags=["films"])
async def get_films(token: str = Header(None)):
    await authorization(userAccess, token=token)
    response = requests.get(f"{service}/films")
    return response.json()


@router.get("/film/{id}", tags=["films"])
async def get_film(id: str, token: str = Header(None)):
    await authorization(userAccess, token=token)
    response = requests.get(f"{service}/film/{id}")
    return response.json()


@router.delete("/films", tags=["films"])
async def delete_all_films(token: str = Header(None)):
    await authorization(userAccess, token=token)
    response = requests.delete(f"{service}/films")
    return response.json()


@router.delete("/film/{id}", tags=["films"])
async def delete_film(id: str, token: str = Header(None)):
    await authorization(moderatorAccess, token=token)
    response = requests.delete(f"{service}/film/{id}")
    return response.json()


@router.post("/film/update", tags=["films"])
async def update_film(film_data: dict, token: str = Header(None)):
    await authorization(moderatorAccess, token=token)
    response = requests.post(f"{service}/film/update", json=film_data)
    return response.json()


@router.post("/film/add", tags=["films"])
async def add_film(film_data: dict, token: str = Header(None)):
    await authorization(moderatorAccess, token=token)
    response = requests.post(f"{service}/film/add", json=film_data)
    return response.json()


# Маршруты для рекомендаций
@router.get("/recommendations/{user}", tags=["recommendations"])
async def get_recommendations_for_user(user: str, token: str = Header(None)):
    await authorization(userAccess, token=token)
    response = requests.get(f"{service}/recommendations/{user}")
    return response.json()


@router.get("/recommendations", tags=["recommendations"])
async def get_recommendations(token: str = Header(None)):
    await authorization(userAccess, token=token)
    response = requests.get(f"{service}/recommendations")
    return response.json()


@router.post("/recommendations/addRequest", tags=["recommendations"])
async def add_recommendation_request(request_data: dict, token: str = Header(None)):
    await authorization(userAccess, token=token)
    response = requests.post(f"{service}/recommendations/addRequest", json=request_data)
    return response.json()
