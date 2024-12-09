from fastapi import FastAPI

from films import router as items_router
from users import router as users_router
from auth import router as auth_router

application = FastAPI()

# Подключение маршрутов
application.include_router(users_router)
application.include_router(items_router)
application.include_router(auth_router)
