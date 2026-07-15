"""
SafeStreet AI
Prediction Request & Response Schemas
"""

from pydantic import BaseModel


class PredictionRequest(BaseModel):
    """
    Crime prediction input.
    """

    latitude: float
    longitude: float

    hour: int
    day_of_week: int
    month: int

    district: int
    community_area: int

    location_description: str


class PredictionResponse(BaseModel):
    """
    Crime prediction output.
    """

    prediction: str
    confidence: float