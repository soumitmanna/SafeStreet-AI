"""
SafeStreet AI
Prediction Routes
"""

from fastapi import APIRouter, Request

from src.schemas.prediction import PredictionRequest, PredictionResponse
from src.utils.exceptions import ModelInferenceError

router = APIRouter(prefix="/api/v1", tags=["Prediction"])


@router.post("/predict", response_model=PredictionResponse)
def predict(request: Request, payload: PredictionRequest):
    """
    Predict crime risk based on location and time features.
    Delegates entirely to the PredictionService.
    """
    prediction_service = getattr(request.app.state, "prediction_service", None)
    if prediction_service is None:
        raise ModelInferenceError("Prediction service is unavailable")
        
    return prediction_service.predict(payload)
