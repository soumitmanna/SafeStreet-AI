"""
SafeStreet AI
Configuration Layer
"""

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """
    Application settings loaded from environment variables and .env file.
    """
    APP_NAME: str = "SafeStreet AI"
    APP_VERSION: str = "1.0.0"
    MODEL_PATH: str = "saved_models/production/safestreet_model.joblib"
    LABEL_ENCODER_PATH: str = "saved_models/production/label_encoder.joblib"
    DEBUG: bool = False

    model_config = SettingsConfigDict(env_file=".env")


# Singleton instance
settings = Settings()
