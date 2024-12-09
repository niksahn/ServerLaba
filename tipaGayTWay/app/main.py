import uvicorn

if __name__ == '__main__':
    uvicorn.run(
        "api:application",
        host='0.0.0.0',
        port=4040,
        reload=True
    )
