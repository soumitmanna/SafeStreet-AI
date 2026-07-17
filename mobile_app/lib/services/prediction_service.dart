import '../models/prediction_request.dart';
import '../models/prediction_response.dart';
import '../network/api_client.dart';

class PredictionService {
  final ApiClient _apiClient;

  /// Creates a new PredictionService. 
  /// Instantiates its own ApiClient by default, but accepts an injected one for testing.
  PredictionService({ApiClient? apiClient}) 
    : _apiClient = apiClient ?? ApiClient();

  /// Sends a prediction request to the FastAPI backend.
  /// 
  /// Returns a [PredictionResponse] on success.
  /// Throws a [PredictionException] on network, server, or validation failures.
  Future<PredictionResponse> predict(PredictionRequest request) async {
    // The ApiClient is responsible for timeout, retry, and throwing typed exceptions.
    final responseMap = await _apiClient.post(
      'api/v1/predict',
      request.toJson(),
    );

    return PredictionResponse.fromJson(responseMap);
  }
}
