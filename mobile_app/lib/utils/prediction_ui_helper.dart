import 'package:flutter/material.dart';
import '../models/prediction_response.dart';
import '../models/prediction_exception.dart';
import '../theme/app_theme.dart';


class PredictionUiHelper {
  static Color colorFor(BuildContext context, RiskLevel level) {
    final statusColors = Theme.of(context).extension<AppStatusColors>();
    switch (level) {
      case RiskLevel.low:
        return statusColors?.success ?? Colors.green;
      case RiskLevel.medium:
        return statusColors?.warning ?? Colors.orange;
      case RiskLevel.high:
        return statusColors?.sos ?? Colors.red;
      case RiskLevel.unknown:
        return Theme.of(context).disabledColor;
    }
  }

  static IconData iconFor(RiskLevel level) {
    switch (level) {
      case RiskLevel.low:
        return Icons.check_circle_outline;
      case RiskLevel.medium:
        return Icons.warning_amber_rounded;
      case RiskLevel.high:
        return Icons.error_outline;
      case RiskLevel.unknown:
        return Icons.help_outline;
    }
  }

  static String labelFor(RiskLevel level) {
    switch (level) {
      case RiskLevel.low:
        return 'Low Risk';
      case RiskLevel.medium:
        return 'Medium Risk';
      case RiskLevel.high:
        return 'High Risk';
      case RiskLevel.unknown:
        return 'Unknown Risk';
    }
  }

  static String messageFor(PredictionErrorType type) {
    switch (type) {
      case PredictionErrorType.network:
        return 'No internet connection or request timed out.';
      case PredictionErrorType.server:
        return 'The prediction service is currently unavailable.';
      case PredictionErrorType.validation:
        return 'Invalid location data submitted.';
    }
  }
}
