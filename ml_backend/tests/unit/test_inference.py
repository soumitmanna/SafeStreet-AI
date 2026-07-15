"""
SafeStreet AI
Unit Tests for Inference Pipeline
"""

import pytest
import math
from src.preprocessing.inference import InferencePipeline
from src.schemas.prediction import PredictionRequest


@pytest.fixture
def pipeline():
    return InferencePipeline()


def test_time_features_morning(pipeline):
    data = {"hour": 9, "day_of_week": 2}
    result = pipeline.create_time_features(data)
    assert result["TimeOfDay"] == "Morning"
    assert result["IsNight"] == 0


def test_time_features_night(pipeline):
    data = {"hour": 23, "day_of_week": 2}
    result = pipeline.create_time_features(data)
    assert result["TimeOfDay"] == "Night"
    assert result["IsNight"] == 1


def test_time_features_weekend(pipeline):
    data = {"hour": 14, "day_of_week": 6}
    result = pipeline.create_time_features(data)
    assert result["IsWeekend"] == 1


def test_time_features_weekday(pipeline):
    data = {"hour": 14, "day_of_week": 2}
    result = pipeline.create_time_features(data)
    assert result["IsWeekend"] == 0


def test_cyclic_hour_zero(pipeline):
    data = {"hour": 0, "month": 1}
    result = pipeline.create_cyclic_features(data)
    assert math.isclose(result["Hour_sin"], 0.0, abs_tol=1e-9)
    assert math.isclose(result["Hour_cos"], 1.0, abs_tol=1e-9)


def test_cyclic_hour_twelve(pipeline):
    data = {"hour": 12, "month": 1}
    result = pipeline.create_cyclic_features(data)
    assert math.isclose(result["Hour_sin"], 0.0, abs_tol=1e-9)
    assert math.isclose(result["Hour_cos"], -1.0, abs_tol=1e-9)


def test_column_order(pipeline, valid_prediction_payload):
    request = PredictionRequest(**valid_prediction_payload)
    df = pipeline.transform(request)
    
    expected_columns = [
        "Latitude", "Longitude", "Hour", "DayOfWeek", "Month", "IsWeekend",
        "District", "Community Area", "Location Description", "TimeOfDay",
        "IsNight", "IsBusinessHours", "Hour_sin", "Hour_cos", "Month_sin", "Month_cos"
    ]
    assert list(df.columns) == expected_columns


def test_transform_single_row(pipeline, valid_prediction_payload):
    request = PredictionRequest(**valid_prediction_payload)
    df = pipeline.transform(request)
    assert len(df) == 1


def test_unknown_location_passes(pipeline, valid_prediction_payload):
    """
    Since model inspection verified OneHotEncoder handles unknown categories,
    the pipeline should successfully pass unknown strings without raising errors.
    """
    payload = valid_prediction_payload.copy()
    payload["location_description"] = "SOME UNKNOWN LOCATION"
    request = PredictionRequest(**payload)
    df = pipeline.transform(request)
    assert df["Location Description"].iloc[0] == "SOME UNKNOWN LOCATION"


def test_no_nan_in_output(pipeline, valid_prediction_payload):
    request = PredictionRequest(**valid_prediction_payload)
    df = pipeline.transform(request)
    assert not df.isnull().values.any()
