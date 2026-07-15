"""
SafeStreet AI
Exception Hierarchy
"""

class SafeStreetBaseError(Exception):
    """Base exception for all SafeStreet AI errors."""
    pass

class ModelLoadError(SafeStreetBaseError):
    """Raised when the model or label encoder fails to load."""
    pass

class PreprocessingError(SafeStreetBaseError):
    """Raised when request preprocessing fails."""
    pass

class ModelInferenceError(SafeStreetBaseError):
    """Raised when the model fails to predict."""
    pass
