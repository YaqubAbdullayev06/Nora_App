import 'package:flutter/foundation.dart';

/// Environment-based configuration for the app.
/// Supports overriding via `--dart-define` at build time:
/// ```
/// flutter run --dart-define=API_BASE_URL=http://my-server:8000 \
///             --dart-define=LLM_BASE_URL=http://my-server:8000 \
///             --dart-define=DEBUG_MODE=true
/// ```
class EnvConfig {
  EnvConfig._();

  static final EnvConfig instance = EnvConfig._();

  /// Backend API base URL.
  final String apiBaseUrl = const String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.0.101:8000',
  );

  /// LLM service base URL (may differ from API).
  final String llmBaseUrl = const String.fromEnvironment(
    'LLM_BASE_URL',
    defaultValue: 'http://192.168.0.101:8000',
  );

  /// Convenience alias used across services.
  String get backendUrl => apiBaseUrl;

  /// Whether debug logging should be enabled.
  final bool debugMode = const bool.fromEnvironment(
    'DEBUG_MODE',
    defaultValue: kDebugMode,
  );

  /// Whether to use mock data instead of real API calls.
  final bool useMockData = const bool.fromEnvironment(
    'USE_MOCK_DATA',
    defaultValue: true,
  );
}
