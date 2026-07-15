"""
SafeStreet AI
Inference Feature Engineering

Note: Inspection of the production model artifact revealed it is a scikit-learn
Pipeline containing `SimpleImputer` and `OneHotEncoder` (for 'Location Description' 
and 'TimeOfDay'). Thus, string encoding is handled by the model itself.
This pipeline only handles time-based derivations and cyclical encoding.
"""

import math
import logging
import pandas as pd

from src.schemas.prediction import PredictionRequest
from src.utils.exceptions import PreprocessingError

logger = logging.getLogger(__name__)


class InferencePipeline:
    """
    Converts API input into a model-ready pandas DataFrame.
    """

    def __init__(self):
        """Initialize the pipeline."""
        pass

    def create_time_features(self, data: dict) -> dict:
        """
        Create all time-based features used during training.
        
        Args:
            data (dict): Raw input features.
            
        Returns:
            dict: Data with newly added temporal features.
        """
        hour = data["hour"]

        # IsWeekend
        data["IsWeekend"] = int(data["day_of_week"] >= 5)

        # TimeOfDay
        if 5 <= hour < 12:
            data["TimeOfDay"] = "Morning"
        elif 12 <= hour < 17:
            data["TimeOfDay"] = "Afternoon"
        elif 17 <= hour < 21:
            data["TimeOfDay"] = "Evening"
        else:
            data["TimeOfDay"] = "Night"

        # IsNight
        data["IsNight"] = int(hour >= 21 or hour < 5)

        # IsBusinessHours
        data["IsBusinessHours"] = int(9 <= hour <= 17)

        return data

    def create_cyclic_features(self, data: dict) -> dict:
        """
        Create cyclical encodings for hour and month.
        
        Args:
            data (dict): Input features.
            
        Returns:
            dict: Data with cyclical encodings added.
        """
        hour = data["hour"]
        month = data["month"]

        data["Hour_sin"] = math.sin(2 * math.pi * hour / 24.0)
        data["Hour_cos"] = math.cos(2 * math.pi * hour / 24.0)
        data["Month_sin"] = math.sin(2 * math.pi * month / 12.0)
        data["Month_cos"] = math.cos(2 * math.pi * month / 12.0)

        return data

    def build_feature_dataframe(self, data: dict) -> pd.DataFrame:
        """
        Construct the final 16-column pandas DataFrame in canonical order.
        
        Args:
            data (dict): Dictionary of computed features.
            
        Returns:
            pd.DataFrame: A single-row DataFrame.
        """
        canonical_order = [
            "Latitude", "Longitude", "Hour", "DayOfWeek", "Month", "IsWeekend",
            "District", "Community Area", "Location Description", "TimeOfDay",
            "IsNight", "IsBusinessHours", "Hour_sin", "Hour_cos", "Month_sin", "Month_cos"
        ]

        # Map API field names to Canonical names
        df_data = {
            "Latitude": [data["latitude"]],
            "Longitude": [data["longitude"]],
            "Hour": [data["hour"]],
            "DayOfWeek": [data["day_of_week"]],
            "Month": [data["month"]],
            "IsWeekend": [data["IsWeekend"]],
            "District": [data["district"]],
            "Community Area": [data["community_area"]],
            "Location Description": [data["location_description"]],
            "TimeOfDay": [data["TimeOfDay"]],
            "IsNight": [data["IsNight"]],
            "IsBusinessHours": [data["IsBusinessHours"]],
            "Hour_sin": [data["Hour_sin"]],
            "Hour_cos": [data["Hour_cos"]],
            "Month_sin": [data["Month_sin"]],
            "Month_cos": [data["Month_cos"]],
        }

        df = pd.DataFrame(df_data, columns=canonical_order)
        return df

    def transform(self, request: PredictionRequest) -> pd.DataFrame:
        """
        Execute all preprocessing steps.
        
        Args:
            request (PredictionRequest): Validated prediction request.
            
        Returns:
            pd.DataFrame: Feature DataFrame ready for inference.
            
        Raises:
            PreprocessingError: If DataFrame construction fails or contains NaNs.
        """
        try:
            data = request.model_dump()
            
            data = self.create_time_features(data)
            data = self.create_cyclic_features(data)
            
            df = self.build_feature_dataframe(data)
            
            if df.isnull().values.any():
                raise ValueError("DataFrame contains NaN values.")
            if len(df.columns) != 16:
                raise ValueError(f"Expected 16 columns, got {len(df.columns)}.")
                
            return df
        except Exception as e:
            logger.warning(f"Preprocessing failed: {e}")
            raise PreprocessingError(f"Preprocessing failed: {e}") from e