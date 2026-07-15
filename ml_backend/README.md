# SafeStreet AI

SafeStreet is an AI-powered women's safety mobile application developed using Flutter.
This repository contains the Production AI Backend, which leverages a trained XGBoost model to predict crime risk.

## Current State

The backend has been completely refactored to production readiness (Phase 9 implementation complete).
- **FastAPI** web framework with liveness/readiness probes.
- **XGBoost** model predictions exposed via JSON endpoints.
- Validated request payloads using **Pydantic**.
- Production-ready **structured error handling** and standardized **logging**.
- Feature engineering fully isolated into a reproducible **Inference Pipeline**.

## Project Setup

### 1. Environment Setup

Create and activate a virtual environment:
```bash
python -m venv .venv
source .venv/bin/activate  # On macOS/Linux
.venv\Scripts\activate     # On Windows
```

Install dependencies:
```bash
pip install -r requirements.txt
```

### 2. Configuration (.env)
Create a `.env` file at the root of `ml_backend` containing exactly the following configuration values (matching the provided template `.env.example`):
```env
APP_NAME="SafeStreet AI"
APP_VERSION="1.0.0"
MODEL_PATH="saved_models/production/safestreet_model.joblib"
LABEL_ENCODER_PATH="saved_models/production/label_encoder.joblib"
DEBUG=false
```

### 3. Launching the Application

**Development (Hot-Reloading Enabled):**
```bash
uvicorn src.api.main:app --reload
```

**Production (Multi-Worker):**
```bash
# Wait to start until the application is deployed behind a reverse proxy
uvicorn src.api.main:app --host 0.0.0.0 --port 8000 --workers 2
```

## Running Tests

Integration and unit tests utilize `pytest` to guarantee system stability and valid predictions.

Run all tests:
```bash
pytest tests/ -v
```

To run with coverage reporting:
```bash
pytest tests/ -v --cov=src --cov-report=term-missing
```
