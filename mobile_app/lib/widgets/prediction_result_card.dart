import 'package:flutter/material.dart';
import '../models/prediction_exception.dart';
import '../models/prediction_response.dart';
import '../utils/prediction_ui_helper.dart';


class PredictionResultCard extends StatelessWidget {
  final PredictionResponse? result;
  final PredictionException? error;
  final bool isLoading;
  final VoidCallback? onRetry;

  const PredictionResultCard({
    super.key,
    this.result,
    this.error,
    this.isLoading = false,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _buildContent(context),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Analyzing location risk...'),
            ],
          ),
        ),
      );
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error, size: 48),
            const SizedBox(height: 12),
            Text(
              PredictionUiHelper.messageFor(error!.type),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (error!.message.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                error!.message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).disabledColor),
              ),
            ],
            const SizedBox(height: 16),
            if (onRetry != null && error!.type != PredictionErrorType.validation)
              ElevatedButton.icon(
                // Disabled if currently loading, avoiding duplicate submissions
                onPressed: isLoading ? null : onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
          ],
        ),
      );
    }

    if (result != null) {
      final color = PredictionUiHelper.colorFor(context, result!.riskLevel);
      
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(PredictionUiHelper.iconFor(result!.riskLevel), color: color, size: 32),
              const SizedBox(width: 8),
              Text(
                PredictionUiHelper.labelFor(result!.riskLevel),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: result!.confidence,
            backgroundColor: color.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
          Text(
            'Confidence: ${result!.confidencePercent}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          Text(
            'Inference time: ${result!.inferenceMs}ms',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).disabledColor),
          ),
        ],
      );
    }

    // Default empty state (before user taps check risk)
    return const Center(
      child: Text('Tap to analyze this location.'),
    );
  }
}
