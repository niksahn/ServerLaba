from fastapi import FastAPI
import os
from typing import Optional
import uvicorn

if __name__ == '__main__':
    uvicorn.run(
        "app:app",
        host='localhost',
        port=4040,
        reload=True
    )