from fastapi import FastAPI
from connection_postgrest import connection

app = FastAPI()


@app.get("/health")
async def health():
    return "OK"


@app.get("/version")
async def version():
    cursor = connection().cursor()

    cursor.execute("SELECT version();")
    current_version = cursor.fetchone()

    cursor.close()
    return {"version": current_version}
