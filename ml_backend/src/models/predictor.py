"""
SafeStreet AI - Model Predictor
"""

from pathlib import Path
import joblib


class CrimeRiskPredictor:
    """
    Loads the trained model once and performs predictions.
    """

    def __init__(self):

        model_dir = Path("saved_models")

        self.model = joblib.load(
            model_dir / "safestreet_xgboost_v1.joblib"
        )

        self.label_encoder = joblib.load(
            model_dir / "label_encoder_v2.joblib"
        )

        print("=" * 60)
        print("✅ SafeStreet AI Model Loaded Successfully")
        print("=" * 60)

def predict(self, features):
    """
    Predict crime risk.
    """

    prediction_encoded = self.model.predict(features)

    prediction = self.label_encoder.inverse_transform(
        prediction_encoded
    )

    return prediction[0]