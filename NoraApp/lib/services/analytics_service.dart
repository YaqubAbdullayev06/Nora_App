import 'package:flutter/foundation.dart';

/// AnalyticsService — lightweight analytics with Firebase (free tier).
///
/// FIREBASE FREE TIER LIMITS:
/// - Analytics: 500,000 events/month
/// - Crashlytics: 50,000 events/day
/// - Remote Config: 1 million reads/month
///
/// These limits are generous for early-stage apps. No cost until you
/// exceed them. Perfect for $0 budget development.
///
/// USAGE:
/// - Log key user actions (focus session started, persona selected)
/// - Track crashes automatically via Crashlytics
/// - Use Remote Config for kill switches and feature flags
class AnalyticsService {
  // In production, this wraps Firebase Analytics + Crashlytics.
  // For now, we use print-based logging for development.
  // To integrate Firebase:
  //   1. flutter pub add firebase_analytics firebase_crashlytics
  //   2. Run `flutterfire configure` to generate firebase_options.dart
  //   3. Replace print statements with Firebase calls

  static bool _initialized = false;

  /// Initialize Firebase Analytics + Crashlytics.
  /// Call once in main() before runApp().
  static Future<void> initialize() async {
    if (_initialized) return;

    if (kIsWeb) {
      // Firebase Analytics for web is optional
      _initialized = true;
      return;
    }

    try {
      // In production, uncomment these:
      // await Firebase.initializeApp(
      //   options: DefaultFirebaseOptions.currentPlatform,
      // );
      // FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);

      _initialized = true;
      debugPrint('[Analytics] Initialized (free tier)');
    } catch (e) {
      debugPrint('[Analytics] Failed to initialize: $e');
    }
  }

  /// Log a custom analytics event.
  ///
  /// Events are sent to Firebase Analytics (free up to 500K/month).
  /// Keep event names under 40 chars, params under 50 chars each.
  static void logEvent(String name, {Map<String, String>? parameters}) {
    if (kDebugMode) {
      debugPrint('[Analytics] $name ${parameters ?? ''}');
    }
    // In production:
    // FirebaseAnalytics.instance.logEvent(
    //   name: name,
    //   parameters: parameters,
    // );
  }

  /// Log a focus session started.
  static void logFocusSessionStarted(int durationMinutes) {
    logEvent('focus_started', parameters: {
      'duration_minutes': durationMinutes.toString(),
    });
  }

  /// Log a focus session completed.
  static void logFocusSessionCompleted(int durationMinutes, bool completed) {
    logEvent('focus_completed', parameters: {
      'duration_minutes': durationMinutes.toString(),
      'completed': completed.toString(),
    });
  }

  /// Log persona selected during onboarding.
  static void logPersonaSelected(String persona) {
    logEvent('persona_selected', parameters: {'persona': persona});
  }

  /// Log AI chat interaction.
  static void logAIChatMessage(String ageGroup) {
    logEvent('ai_chat_message', parameters: {'age_group': ageGroup});
  }

  /// Log app blocking action.
  static void logAppBlocked(int appCount) {
    logEvent('apps_blocked', parameters: {
      'app_count': appCount.toString(),
    });
  }

  /// Log crash (for non-Firebase fallback).
  static void recordError(dynamic error, StackTrace stack, {String? reason}) {
    if (kDebugMode) {
      debugPrint('[Crashlytics] ERROR: $error');
      debugPrint('[Crashlytics] Stack: $stack');
    }
    // In production:
    // FirebaseCrashlytics.instance.recordError(
    //   error,
    //   stack,
    //   reason: reason,
    // );
  }

  /// Set user identifier for crash reports (optional).
  static void setUserIdentifier(String userId) {
    // In production:
    // FirebaseCrashlytics.instance.setUserIdentifier(userId);
  }

  /// Log a custom key for crash context.
  static void setCustomKey(String key, String value) {
    // In production:
    // FirebaseCrashlytics.instance.setCustomKey(key, value);
  }
}
