"""
SafeStreet AI Backend
Main FastAPI Application
"""

from fastapi import FastAPI

from src.models.predictor import CrimeRiskPredictor

from src.schemas.prediction import (
    PredictionRequest,
    PredictionResponse,
)

# =====================================================
# Create FastAPI App
# =====================================================

app = FastAPI(
    title="SafeStreet AI API",
    description="Crime Risk Prediction API",
    version="1.0.0",
)

# =====================================================
# Load ML Model Once
# =====================================================

predictor = CrimeRiskPredictor()

# =====================================================
# Routes
# =====================================================

@app.get("/")
def home():
    return {
        "message": "Welcome to SafeStreet AI Backend",
        "status": "running",
    }


@app.get("/health")
def health():
    return {
        "status": "healthy",
        "model": "Loaded",
    }

# =====================================================
# Test Prediction Endpoint
# =====================================================

@app.post(
    "/predict",
    response_model=PredictionResponse,
)
def predict(request: PredictionRequest):

    print(request)

    return PredictionResponse(
        prediction="Low",
        confidence=0.91,
    )