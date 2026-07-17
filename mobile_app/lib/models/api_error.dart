class ApiError {
  final String error;
  final String message;

  const ApiError({
    required this.error,
    required this.message,
  });

  /// Safely parses the FastAPI error response envelope.
  factory ApiError.fromJson(Map<String, dynamic> json) {
    return ApiError(
      error: json['error']?.toString() ?? 'UnknownError',
      message: json['message']?.toString() ?? 'An unexpected error occurred.',
    );
  }
}
