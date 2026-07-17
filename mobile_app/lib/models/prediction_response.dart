enum RiskLevel { low, medium, high, unknown }

class PredictionResponse {
  final String prediction;
  final double confidence;
  final double inferenceMs;

  const PredictionResponse({
    required this.prediction,
    required this.confidence,
    required this.inferenceMs,
  });

  /// Safely parses JSON. If fields are missing or wrong type, provides safe fallbacks
  /// without crashing the application.
  factory PredictionResponse.fromJson(Map<String, dynamic> json) {
    return PredictionResponse(
      prediction: json['prediction']?.toString() ?? 'Unknown',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      inferenceMs: (json['inference_ms'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Converts the raw string prediction into a strongly-typed enum for UI mapping.
  RiskLevel get riskLevel {
    switch (prediction.toLowerCase()) {
      case 'low':
        return RiskLevel.low;
      case 'medium':
        return RiskLevel.medium;
      case 'high':
        return RiskLevel.high;
      default:
        return RiskLevel.unknown;
    }
  }

  /// Formats the confidence score as a clean percentage string.
  String get confidencePercent => '${(confidence * 100).toStringAsFixed(1)}%';
}
