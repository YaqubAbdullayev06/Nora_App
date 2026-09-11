import 'package:flutter/foundation.dart';

/// RemoteConfigService — remote feature flags via Firebase Remote Config.
///
/// FREE TIER: 1 million reads/month. More than enough for kill switches.
///
/// USE CASES:
/// - Kill switch: instantly disable app blocking if it causes crashes
/// - Feature flags: toggle features without app updates
/// - Config: change AI model parameters remotely
///
/// SETUP:
/// 1. `flutter pub add firebase_remote_config`
/// 2. Configure Firebase in your project
/// 3. Set default values in firebase_remote_config_defaults.xml
class RemoteConfigService {
  // Default values (used if Firebase is unavailable or not configured)
  static const _defaults = {
    'blocking_enabled': true,
    'ai_chat_enabled': true,
    'crisis_detection_enabled': true,
    'min_app_version': '1.0.0',
    'maintenance_mode': false,
  };

  static Map<String, dynamic> _values = Map.from(_defaults);
  static bool _initialized = false;

  /// Initialize Remote Config. Call once at app start.
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      // In production, uncomment these:
      // await FirebaseRemoteConfig.instance.setConfigSettings(
      //   RemoteConfigSettings(
      //     fetchTimeout: const Duration(seconds: 10),
      //     minimumFetchInterval: const Duration(hours: 1),
      //   ),
      // );
      // await FirebaseRemoteConfig.instance.setDefaults(_defaults);
      // await FirebaseRemoteConfig.instance.fetchAndActivate();

      // Read values from (simulated) Remote Config
      // In production: _values = FirebaseRemoteConfig.instance.getAll();

      _initialized = true;
      debugPrint('[RemoteConfig] Initialized with defaults');
    } catch (e) {
      debugPrint('[RemoteConfig] Failed to initialize: $e');
    }
  }

  /// Check if app blocking is enabled (kill switch).
  /// Set this to false in Firebase Console to instantly disable blocking.
  static bool get blockingEnabled => _values['blocking_enabled'] == true;

  /// Check if AI chat is enabled.
  static bool get aiChatEnabled => _values['ai_chat_enabled'] == true;

  /// Check if crisis detection is enabled.
  static bool get crisisDetectionEnabled =>
      _values['crisis_detection_enabled'] == true;

  /// Get minimum required app version.
  static String get minAppVersion =>
      _values['min_app_version']?.toString() ?? '1.0.0';

  /// Check if app is in maintenance mode.
  static bool get maintenanceMode => _values['maintenance_mode'] == true;

  /// Get a config value by key.
  static dynamic getValue(String key) => _values[key];

  /// Force refresh from Firebase (for debugging).
  static Future<void> refresh() async {
    try {
      // In production:
      // await FirebaseRemoteConfig.instance.fetchAndActivate();
      // _values = FirebaseRemoteConfig.instance.getAll();
      debugPrint('[RemoteConfig] Refreshed');
    } catch (e) {
      debugPrint('[RemoteConfig] Refresh failed: $e');
    }
  }
}
