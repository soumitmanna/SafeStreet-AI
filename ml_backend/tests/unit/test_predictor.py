"""
SafeStreet AI
Unit Tests for Model Predictor
"""

import pytest
from unittest.mock import patch, MagicMock
import pandas as pd
import numpy as np

from src.models.predictor import CrimeRiskPredictor
from src.utils.exceptions import ModelLoadError


@patch("src.models.predictor.Path.exists")
@patch("src.models.predictor.joblib.load")
def test_predict_returns_string_label(mock_load, mock_exists):
    mock_exists.return_value = True
    mock_model = MagicMock()
    mock_model.predict.return_value = np.array([2])
    mock_model.predict_proba.return_value = np.array([[0.1, 0.2, 0.7]])
    
    mock_encoder = MagicMock()
    mock_encoder.inverse_transform.return_value = np.array(["High"])
    
    mock_load.side_effect = [mock_model, mock_encoder]
    
    predictor = CrimeRiskPredictor("dummy_model_path", "dummy_encoder_path")
    features = pd.DataFrame({"dummy": [1]})
    
    label, confidence = predictor.predict_with_confidence(features)
    
    assert isinstance(label, str)
    assert label == "High"
    assert math.isclose(confidence, 0.7, abs_tol=1e-5)

import math

@patch("src.models.predictor.Path.exists")
@patch("src.models.predictor.joblib.load")
def test_confidence_in_valid_range(mock_load, mock_exists):
    mock_exists.return_value = True
    mock_model = MagicMock()
    mock_model.predict.return_value = np.array([0])
    mock_model.predict_proba.return_value = np.array([[0.8, 0.1, 0.1]])
    
    mock_encoder = MagicMock()
    mock_encoder.inverse_transform.return_value = np.array(["Low"])
    
    mock_load.side_effect = [mock_model, mock_encoder]
    
    predictor = CrimeRiskPredictor("dummy_model", "dummy_encoder")
    features = pd.DataFrame({"dummy": [1]})
    
    label, confidence = predictor.predict_with_confidence(features)
    
    assert 0.0 <= confidence <= 1.0


@patch("src.models.predictor.Path.exists")
def test_model_load_failure_raises(mock_exists):
    mock_exists.side_effect = [False, True]  # Model not found, Encoder found
    with pytest.raises(ModelLoadError):
        CrimeRiskPredictor("bad_model_path", "valid_encoder_path")


@patch("src.models.predictor.Path.exists")
def test_encoder_load_failure_raises(mock_exists):
    mock_exists.side_effect = [True, False]  # Model found, Encoder not found
    with pytest.raises(ModelLoadError):
        CrimeRiskPredictor("valid_model_path", "bad_encoder_path")
