"""
PropZen Autonomous AI Microservice & Secure Encryption Gateway
FastAPI Application Entrypoint
"""

import os
from fastapi import FastAPI, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

from .routers.ai_router import router as ai_router
from .routers.seo_router import router as seo_router
from .routers.government_router import router as govt_router
from .routers.external_services_router import router as ext_router

app = FastAPI(
    title="PropZen Autonomous AI & Security Gateway",
    version="3.0.0",
    description="Enterprise LangGraph Decision Engine, CrewAI Reasoning, Programmatic SEO, and Government API Envelope Encryption.",
)

# CORS Configuration
origins = [
    "https://propzen.ai",
    "https://www.propzen.ai",
    "http://localhost:8080",
    "http://127.0.0.1:8080",
    "http://localhost:3000",
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], # Restricted in production gateway
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include API Routers
app.include_router(ai_router)
app.include_router(seo_router)
app.include_router(govt_router)
app.include_router(ext_router)

# Mount PropZen GlobalVerificationEngine
try:
    from backend.verification_engine.api.v1.verification import router as verification_router
    app.include_router(verification_router)
except Exception:
    try:
        from ..verification_engine.api.v1.verification import router as verification_router
        app.include_router(verification_router)
    except Exception:
        pass


@app.get("/health", tags=["System"])
async def health_check():
    return {
        "status": "HEALTHY",
        "service": "PropZen Autonomous AI & Encryption Microservice",
        "version": "3.0.0",
        "langgraph_decision_engine": "ACTIVE",
        "crewai_reasoning_layer": "ACTIVE",
        "kms_envelope_encryption": "ACTIVE",
    }


@app.get("/", tags=["System"])
async def root():
    return {
        "message": "PropZen AI Autonomous Backend is operational.",
        "docs": "/docs",
        "health": "/health",
    }


if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("AI_ENGINE_PORT", 8000))
    host = os.getenv("AI_ENGINE_HOST", "0.0.0.0")
    uvicorn.run("main:app", host=host, port=port, reload=True)
