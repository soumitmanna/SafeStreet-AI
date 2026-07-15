"""
SafeStreet AI
Integration Tests for API Endpoints
"""

from unittest.mock import MagicMock

def test_health_200(app_client):
    response = app_client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "ok"


def test_ready_200(app_client):
    # Depending on test environment, model might actually be loaded by lifespan
    response = app_client.get("/ready")
    assert response.status_code == 200
    assert response.json()["status"] == "ready"


def test_predict_valid_returns_200(app_client, valid_prediction_payload):
    response = app_client.post("/api/v1/predict", json=valid_prediction_payload)
    assert response.status_code == 200
    data = response.json()
    assert data["prediction"] in {"Low", "Medium", "High"}


def test_predict_confidence_float(app_client, valid_prediction_payload):
    response = app_client.post("/api/v1/predict", json=valid_prediction_payload)
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data["confidence"], float)
    assert 0.0 <= data["confidence"] <= 1.0


def test_predict_has_inference_ms(app_client, valid_prediction_payload):
    response = app_client.post("/api/v1/predict", json=valid_prediction_payload)
    assert response.status_code == 200
    data = response.json()
    assert "inference_ms" in data
    assert data["inference_ms"] > 0


def test_predict_invalid_hour(app_client, valid_prediction_payload):
    payload = valid_prediction_payload.copy()
    payload["hour"] = 25
    response = app_client.post("/api/v1/predict", json=payload)
    assert response.status_code == 422
    data = response.json()
    assert data["error"] == "ValidationError"


def test_predict_invalid_latitude(app_client, valid_prediction_payload):
    payload = valid_prediction_payload.copy()
    payload["latitude"] = 999
    response = app_client.post("/api/v1/predict", json=payload)
    assert response.status_code == 422
    data = response.json()
    assert data["error"] == "ValidationError"


def test_predict_missing_field(app_client, valid_prediction_payload):
    payload = valid_prediction_payload.copy()
    del payload["longitude"]
    response = app_client.post("/api/v1/predict", json=payload)
    assert response.status_code == 422
    data = response.json()
    assert data["error"] == "ValidationError"


def test_predict_unknown_location(app_client, valid_prediction_payload):
    """
    Since model inspection verified the model pipeline has a OneHotEncoder configured
    to ignore unknown categories, this should actually succeed.
    """
    payload = valid_prediction_payload.copy()
    payload["location_description"] = "A RANDOM UNKNOWN LOCATION"
    response = app_client.post("/api/v1/predict", json=payload)
    assert response.status_code == 200
    assert "prediction" in response.json()


def test_no_stack_trace_in_422(app_client, valid_prediction_payload):
    payload = valid_prediction_payload.copy()
    payload["hour"] = 25
    response = app_client.post("/api/v1/predict", json=payload)
    assert response.status_code == 422
    data = response.json()
    assert "Traceback" not in data["message"]
    assert "Traceback" not in response.text


def test_no_stack_trace_in_500(app_client, valid_prediction_payload):
    # We can force a 500 error by removing the prediction service temporarily
    app_client.app.state.prediction_service = None
    response = app_client.post("/api/v1/predict", json=valid_prediction_payload)
    assert response.status_code == 500
    data = response.json()
    assert "Traceback" not in data.get("message", "")
    assert "Traceback" not in response.text
