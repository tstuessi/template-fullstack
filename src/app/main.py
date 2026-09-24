import logging
from pathlib import Path

from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles

from app.settings import get_settings

settings = get_settings()
logging.basicConfig(level=settings.log_level)

app = FastAPI(title="fullstack-template")


@app.get("/api/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


@app.get("/api/hello")
def hello() -> dict[str, str]:
    return {"message": "Hello from FastAPI"}


# In prod, `task build` copies the built frontend into src/app/static —
# absent in dev, where Vite serves the frontend itself and proxies /api.
_static_dir = Path(__file__).parent / "static"
if _static_dir.is_dir():
    app.mount("/", StaticFiles(directory=_static_dir, html=True), name="static")
