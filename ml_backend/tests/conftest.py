"""
SafeStreet AI
Shared Test Fixtures
"""

import pytest
from unittest.mock import MagicMock
from fastapi.testclient import TestClient

from src.api.main import app
from src.models.predictor import CrimeRiskPredictor


@pytest.fixture
def app_client():
    """Provides a TestClient for the FastAPI app."""
    # We use a context manager to trigger lifespan events in the test client
    with TestClient(app) as client:
        yield client


@pytest.fixture
def valid_prediction_payload():
    """Provides a valid JSON payload for prediction requests."""
    return {
        "latitude": 41.881,
        "longitude": -87.623,
        "hour": 22,
        "day_of_week": 5,
        "month": 7,
        "district": 1,
        "community_area": 8,
        "location_description": "STREET"
    }


@pytest.fixture
def mock_predictor():
    """Provides a mocked predictor to avoid loading large model files during unit tests."""
    predictor = MagicMock(spec=CrimeRiskPredictor)
    predictor.predict_with_confidence.return_value = ("High", 0.95)
    return predictor
