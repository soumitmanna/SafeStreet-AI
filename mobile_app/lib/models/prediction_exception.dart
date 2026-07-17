enum PredictionErrorType { network, server, validation }

class PredictionException implements Exception {
  final PredictionErrorType type;
  final String message;
  final int? statusCode;

  PredictionException(this.type, this.message, [this.statusCode]);

  @override
  String toString() => 'PredictionException($type): $message (status: $statusCode)';
}
