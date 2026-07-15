"""
SafeStreet AI
Prediction Service Layer
"""

import time
import logging
from src.schemas.prediction import PredictionRequest, PredictionResponse
from src.preprocessing.inference import InferencePipeline
from src.models.predictor import CrimeRiskPredictor
from src.utils.exceptions import PreprocessingError, ModelInferenceError

logger = logging.getLogger(__name__)


class PredictionService:
    """
    Orchestrates the prediction workflow.
    Decouples API routes from the model and preprocessing pipeline.
    """

    def __init__(self, pipeline: InferencePipeline, predictor: CrimeRiskPredictor):
        """
        Initialize the service with injected dependencies.
        
        Args:
            pipeline (InferencePipeline): Preprocessing pipeline.
            predictor (CrimeRiskPredictor): The machine learning model predictor.
        """
        self.pipeline = pipeline
        self.predictor = predictor

    def predict(self, request: PredictionRequest) -> PredictionResponse:
        """
        Process the request, perform inference, and return the response.
        
        Args:
            request (PredictionRequest): The validated API request.
            
        Returns:
            PredictionResponse: The predicted risk level and confidence.
            
        Raises:
            PreprocessingError: If feature engineering fails.
            ModelInferenceError: If model prediction fails.
        """
        logger.info("Prediction started")
        start_time = time.perf_counter()

        try:
            # Step 1: Preprocess request into DataFrame
            features_df = self.pipeline.transform(request)
        except PreprocessingError:
            raise
        except Exception as e:
            logger.warning(f"Unexpected error during preprocessing: {e}")
            raise PreprocessingError(f"Unexpected error during preprocessing: {e}") from e

        try:
            # Step 2: Model Inference
            label, confidence = self.predictor.predict_with_confidence(features_df)
        except ModelInferenceError:
            raise
        except Exception as e:
            logger.error(f"Unexpected error during inference: {e}")
            raise ModelInferenceError(f"Unexpected error during inference: {e}") from e

        end_time = time.perf_counter()
        inference_ms = round((end_time - start_time) * 1000, 2)

        logger.info(f"Prediction complete: label={label}, confidence={confidence:.3f}, latency={inference_ms}ms")

        # Step 3: Build response
        return PredictionResponse(
            prediction=label,
            confidence=confidence,
            inference_ms=inference_ms
        )
