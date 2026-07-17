class AppConfig {
  /// Defines the application environment: 'emulator', 'device', or 'production'.
  /// Defaults to 'emulator'.
  static const String _env = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'emulator',
  );

  /// Explicit override for the API base URL.
  /// Has the highest priority if provided.
  static const String _apiBaseUrlOverride = String.fromEnvironment('API_BASE_URL');

  /// Resolves the base URL for the FastAPI backend based on the environment strategy.
  static String get baseUrl {
    if (_apiBaseUrlOverride.isNotEmpty) {
      return _apiBaseUrlOverride;
    }

    switch (_env) {
      case 'production':
        return 'https://api.safestreet.ai';
      case 'device':
        // Expects --dart-define=API_BASE_URL=<LAN-IP> to be provided.
        // If it was missing, we fallback to a safe placeholder.
        return 'http://<LAN-IP>:8000'; 
      case 'emulator':
      default:
        // Android Emulator loopback
        return 'http://10.0.2.2:8000';
    }
  }

  /// Timeout for API requests in seconds.
  static const int timeoutSeconds = 30;

  /// Maximum number of retries for transient errors (network drops, 5xx).
  static const int maxRetries = 1;
}
