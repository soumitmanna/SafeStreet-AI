import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/prediction_exception.dart';

class ApiClient {
  final http.Client _client;

  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    // Construct URL without string concatenation
    final baseUri = Uri.parse(AppConfig.baseUrl);
    final uri = baseUri.resolve(endpoint);
    
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    int attempt = 0;
    while (attempt <= AppConfig.maxRetries) {
      try {
        final response = await _client
            .post(
              uri,
              headers: headers,
              body: jsonEncode(body),
            )
            .timeout(const Duration(seconds: AppConfig.timeoutSeconds));

        if (response.statusCode >= 200 && response.statusCode < 300) {
          return jsonDecode(response.body) as Map<String, dynamic>;
        }

        if (response.statusCode == 422) {
          throw PredictionException(
            PredictionErrorType.validation,
            'Invalid request payload.',
            response.statusCode,
          );
        }

        if (response.statusCode >= 500) {
          if (attempt < AppConfig.maxRetries) {
            attempt++;
            await Future.delayed(const Duration(milliseconds: 500));
            continue;
          }
          throw PredictionException(
            PredictionErrorType.server,
            'Server error occurred.',
            response.statusCode,
          );
        }

        // 400, 401, 403, 404, etc. No retry.
        throw PredictionException(
          PredictionErrorType.server, 
          'Request failed.',
          response.statusCode,
        );
      } on TimeoutException {
        if (attempt < AppConfig.maxRetries) {
          attempt++;
          continue;
        }
        throw PredictionException(
          PredictionErrorType.network,
          'Request timed out.',
        );
      } on SocketException {
        if (attempt < AppConfig.maxRetries) {
          attempt++;
          await Future.delayed(const Duration(milliseconds: 500));
          continue;
        }
        throw PredictionException(
          PredictionErrorType.network,
          'No internet connection.',
        );
      } on http.ClientException {
        if (attempt < AppConfig.maxRetries) {
          attempt++;
          await Future.delayed(const Duration(milliseconds: 500));
          continue;
        }
        throw PredictionException(
          PredictionErrorType.network,
          'Network connection failed.',
        );
      } on FormatException {
        // Do not retry on JSON parsing failures
        throw PredictionException(
          PredictionErrorType.server,
          'Invalid response format.',
        );
      }
    }
    
    // Should never reach here due to exception throws, but required by dart compiler
    throw PredictionException(
      PredictionErrorType.network,
      'Max retries exceeded.',
    );
  }
}
