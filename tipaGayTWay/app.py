from fastapi import FastAPI

from films import router as items_router
from users import router as users_router
from auth import router as auth_router

app = FastAPI()

# Подключение маршрутов
app.include_router(users_router, prefix="/api/users")
app.include_router(items_router, prefix="/api/films")
app.include_router(auth_router, prefix="/api/auth")