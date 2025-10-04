from fastapi import FastAPI

from films import router as items_router
from users import router as users_router
from auth import router as auth_router
from metrics import setup_metrics_middleware

application = FastAPI()

# Setup metrics
setup_metrics_middleware(application)

# Подключение маршрутов
application.include_router(users_router)
application.include_router(items_router)
application.include_router(auth_router)
