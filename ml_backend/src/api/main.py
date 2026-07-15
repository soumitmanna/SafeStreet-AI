"""
SafeStreet AI Backend
Main FastAPI Application
"""

import logging
import sys
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware

from src.config.settings import settings
from src.utils.exceptions import PreprocessingError, ModelInferenceError, ModelLoadError
from src.models.predictor import CrimeRiskPredictor
from src.preprocessing.inference import InferencePipeline
from src.services.prediction_service import PredictionService
from src.api.routes import health, prediction

# =====================================================
# Logging Configuration
# =====================================================
log_level = logging.DEBUG if settings.DEBUG else logging.INFO
logging.basicConfig(
    level=log_level,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
    stream=sys.stdout
)
logger = logging.getLogger(__name__)


# =====================================================
# Lifespan Events (Startup & Shutdown)
# =====================================================
@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Handles application startup and shutdown events.
    Loads the machine learning models and initializes the prediction service.
    """
    logger.info(f"Starting {settings.APP_NAME} v{settings.APP_VERSION}")
    
    try:
        # Initialize dependencies
        predictor = CrimeRiskPredictor(
            model_path=settings.MODEL_PATH,
            label_encoder_path=settings.LABEL_ENCODER_PATH
        )
        pipeline = InferencePipeline()
        
        # Initialize orchestration service
        prediction_service = PredictionService(pipeline=pipeline, predictor=predictor)
        
        # Store in app state
        app.state.prediction_service = prediction_service
        logger.info("Application startup complete. Model is ready to serve traffic.")
        
    except Exception as e:
        logger.critical(f"Failed to start application: {e}")
        # Force exit if model cannot load.
        sys.exit(1)

    yield

    logger.info("Application shutdown complete.")


# =====================================================
# Create FastAPI App
# =====================================================
app = FastAPI(
    title=settings.APP_NAME,
    version=settings.APP_VERSION,
    description="Crime Risk Prediction API",
    lifespan=lifespan
)

# =====================================================
# Middleware
# =====================================================
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Adjust for production based on flutter client requirements
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# =====================================================
# Global Exception Handlers
# =====================================================
@app.exception_handler(PreprocessingError)
async def preprocessing_error_handler(request: Request, exc: PreprocessingError):
    logger.warning(f"Preprocessing error: {exc}")
    return JSONResponse(
        status_code=422,
        content={"error": "PreprocessingError", "message": str(exc)}
    )

@app.exception_handler(ModelInferenceError)
async def model_inference_error_handler(request: Request, exc: ModelInferenceError):
    logger.error(f"Model inference error: {exc}")
    return JSONResponse(
        status_code=500,
        content={"error": "ModelInferenceError", "message": "An error occurred during model inference."}
    )

@app.exception_handler(RequestValidationError)
async def validation_error_handler(request: Request, exc: RequestValidationError):
    return JSONResponse(
        status_code=422,
        content={"error": "ValidationError", "message": str(exc)}
    )

@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    logger.error(f"Unhandled exception: {exc}", exc_info=True)
    return JSONResponse(
        status_code=500,
        content={"error": "InternalServerError", "message": "An unexpected error occurred."}
    )


# =====================================================
# Routers
# =====================================================
app.include_router(health.router)
app.include_router(prediction.router)