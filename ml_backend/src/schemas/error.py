"""
SafeStreet AI
Error Schema
"""

from pydantic import BaseModel


class ErrorResponse(BaseModel):
    """
    Standardized error envelope for HTTP responses.
    """
    error: str
    message: str
