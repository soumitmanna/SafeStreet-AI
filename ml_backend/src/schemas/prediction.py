"""
SafeStreet AI
Prediction Request & Response Schemas
"""

from pydantic import BaseModel, Field


class PredictionRequest(BaseModel):
    """
    Crime prediction input.
    All fields are validated for domain constraints.
    """

    latitude: float = Field(
        ..., ge=-90.0, le=90.0,
        description="Latitude of the location",
        json_schema_extra={"example": 41.881}
    )
    longitude: float = Field(
        ..., ge=-180.0, le=180.0,
        description="Longitude of the location",
        json_schema_extra={"example": -87.623}
    )

    hour: int = Field(
        ..., ge=0, le=23,
        description="Hour of the day (0-23)",
        json_schema_extra={"example": 22}
    )
    day_of_week: int = Field(
        ..., ge=0, le=6,
        description="Day of the week (0=Monday, 6=Sunday)",
        json_schema_extra={"example": 5}
    )
    month: int = Field(
        ..., ge=1, le=12,
        description="Month of the year (1-12)",
        json_schema_extra={"example": 7}
    )

    district: int = Field(
        ..., gt=0,
        description="Police district number",
        json_schema_extra={"example": 1}
    )
    community_area: int = Field(
        ..., gt=0,
        description="Community area number",
        json_schema_extra={"example": 8}
    )

    location_description: str = Field(
        ..., min_length=1,
        description="Description of the location type",
        json_schema_extra={"example": "STREET"}
    )


class PredictionResponse(BaseModel):
    """
    Crime prediction output.
    """

    prediction: str = Field(
        ..., description="Predicted crime risk level", json_schema_extra={"example": "High"}
    )
    confidence: float = Field(
        ..., description="Confidence of the prediction (0.0 to 1.0)", json_schema_extra={"example": 0.847}
    )
    inference_ms: float = Field(
        ..., description="Inference latency in milliseconds", json_schema_extra={"example": 12.4}
    )