"""
PropZen GlobalVerificationEngine - FastAPI Application Entrypoint
Autonomous AI-assisted real estate document verification microservice.
"""
import os
import uvicorn
from fastapi import FastAPI, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from dotenv import load_dotenv

# Load local environment if present
load_dotenv()

from .core.config import settings
from .api.v1.verification import router as verification_router

app = FastAPI(
    title=settings.SERVICE_NAME,
    version=settings.VERSION,
    description=(
        "Production-ready MVP for PropZen GlobalVerificationEngine. "
        "Accepts real estate documents, extracts structured data, runs deterministic validation "
        "and cross-document correlation, scores risk, and returns actionable verification intelligence."
    ),
    docs_url="/docs",
    redoc_url="/redoc",
)

# CORS Middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Mount Verification Router
app.include_router(verification_router)


@app.get("/", tags=["System"])
async def root():
    return {
        "service": settings.SERVICE_NAME,
        "version": settings.VERSION,
        "status": "OPERATIONAL",
        "docs": "/docs",
        "health": "/api/v1/verification/health",
        "ai_provider": settings.AI_PROVIDER,
    }


@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={
            "error": "Internal Server Error",
            "detail": "An unexpected error occurred during document processing.",
            "service": settings.SERVICE_NAME,
        },
    )


if __name__ == "__main__":
    port = int(os.getenv("VERIFICATION_PORT", 8000))
    host = os.getenv("VERIFICATION_HOST", "0.0.0.0")
    uvicorn.run("main:app", host=host, port=port, reload=True)
