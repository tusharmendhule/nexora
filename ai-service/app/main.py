from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.routes.v1 import router as v1_router

app = FastAPI(
    title="Nexora AI Service",
    description="Model inference and NLP processing for Nexora trust scoring.",
    version="0.1.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(v1_router)


@app.get("/health", tags=["health"])
async def health():
    return {"status": "ok", "service": "nexora-ai", "time": __import__("datetime").datetime.utcnow().isoformat()}
