"""
SafeStreet AI
Model Predictor
"""

import logging
from pathlib import Path
import joblib
import pandas as pd
import numpy as np

from src.utils.exceptions import ModelLoadError, ModelInferenceError

logger = logging.getLogger(__name__)


class CrimeRiskPredictor:
    """
    Loads the trained model once and performs predictions.
    """

    def __init__(self, model_path: str, label_encoder_path: str):
        """
        Initialize the predictor by loading the model and encoder artifacts.
        """
        try:
            model_file = Path(model_path)
            encoder_file = Path(label_encoder_path)
            
            if not model_file.exists():
                raise FileNotFoundError(f"Model file not found: {model_file}")
            if not encoder_file.exists():
                raise FileNotFoundError(f"Encoder file not found: {encoder_file}")

            self.model = joblib.load(model_file)
            self.label_encoder = joblib.load(encoder_file)
            
            logger.info("✅ SafeStreet AI Model Loaded Successfully")
        except Exception as e:
            logger.critical(f"Failed to load model or encoder: {e}")
            raise ModelLoadError(f"Failed to load model: {e}") from e

    def predict_with_confidence(self, features: pd.DataFrame) -> tuple[str, float]:
        """
        Predict crime risk and return the label with confidence.
        
        Args:
            features (pd.DataFrame): Single-row DataFrame with exact columns expected by the model.
            
        Returns:
            tuple[str, float]: Decoded label and maximum class probability.
        """
        try:
            prediction_encoded = self.model.predict(features)
            probabilities = self.model.predict_proba(features)
            
            prediction = self.label_encoder.inverse_transform(prediction_encoded)[0]
            confidence = float(np.max(probabilities[0]))
            
            return prediction, confidence
        except Exception as e:
            logger.error(f"Model inference failed: {e}")
            raise ModelInferenceError(f"Model inference failed: {e}") from e