"""
SafeStreet AI
Health & Readiness Routes
"""

from fastapi import APIRouter, Request, Response, status
from src.config.settings import settings

router = APIRouter(tags=["Health"])


@router.get("/health")
def health_check():
    """Liveness probe: verifies the service is running."""
    return {
        "status": "ok",
        "version": settings.APP_VERSION
    }


@router.get("/ready")
def readiness_check(request: Request, response: Response):
    """
    Readiness probe: verifies the model is loaded and ready to serve traffic.
    Returns 503 if the service is not ready.
    """
    if hasattr(request.app.state, "prediction_service") and request.app.state.prediction_service is not None:
        return {"status": "ready"}
    
    response.status_code = status.HTTP_503_SERVICE_UNAVAILABLE
    return {"status": "unavailable"}
