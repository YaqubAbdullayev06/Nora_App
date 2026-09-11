import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// FocusProtectionStatus — platform-specific blocking status.
///
/// PLATFORM DIFFERENCES:
/// - Android: AccessibilityService + UsageStatsManager. Requires:
///   1. Permissions Declaration Form for Play Store
///   2. "Restricted settings" handling for sideloaded installs (Android 13+)
///   3. User must manually grant Usage Access + Accessibility permissions
///   4. Blocking overlays the app with a block screen
///
/// - iOS: Screen Time API with FamilyActivityPicker. Apps are opaque
///   ApplicationTokens — cannot resolve to bundle IDs or names.
///   Classification happens by category (social, entertainment, etc.).
///   The AI advises on aggregate patterns, not named apps.
///
/// - Web/Unsupported: No native blocking available.
class FocusProtectionStatus {
  const FocusProtectionStatus({
    required this.supported,
    required this.authorized,
    required this.usageAccessGranted,
    required this.accessibilityGranted,
    required this.blockingEnabled,
    required this.blockedApps,
    required this.message,
    required this.platform,
  });

  final bool supported;
  final bool authorized;
  final bool usageAccessGranted;
  final bool accessibilityGranted;
  final bool blockingEnabled;
  final List<String> blockedApps;
  final String message;
  final FocusPlatform platform;

  factory FocusProtectionStatus.fromMap(Map<dynamic, dynamic> map) {
    return FocusProtectionStatus(
      supported: map['supported'] == true,
      authorized: map['authorized'] == true,
      usageAccessGranted: map['usageAccessGranted'] == true,
      accessibilityGranted: map['accessibilityGranted'] == true,
      blockingEnabled: map['blockingEnabled'] == true,
      blockedApps: (map['blockedPackages'] as List<dynamic>? ?? [])
          .map((item) => item.toString())
          .toList(),
      message:
          map['message'] as String? ?? 'Focus protection status unavailable.',
      platform: _detectPlatform(),
    );
  }

  static FocusPlatform _detectPlatform() {
    if (kIsWeb) return FocusPlatform.web;
    if (Platform.isIOS) return FocusPlatform.ios;
    if (Platform.isAndroid) return FocusPlatform.android;
    return FocusPlatform.unknown;
  }

  static const unsupported = FocusProtectionStatus(
    supported: false,
    authorized: false,
    usageAccessGranted: false,
    accessibilityGranted: false,
    blockingEnabled: false,
    blockedApps: [],
    message: 'This platform does not provide focus protection controls.',
    platform: FocusPlatform.unknown,
  );

  /// iOS-specific status: FamilyActivityPicker categories selected.
  bool get hasIOSCategories => platform == FocusPlatform.ios && authorized;

  /// Android-specific: both permissions granted.
  bool get hasAndroidPermissions =>
      platform == FocusPlatform.android &&
      usageAccessGranted &&
      accessibilityGranted;

  /// Human-readable status for UI.
  String get statusSummary {
    if (!supported) return 'Not supported on this platform';
    if (platform == FocusPlatform.ios) {
      if (authorized) return 'Screen Time access granted';
      return 'Screen Time access required';
    }
    if (platform == FocusPlatform.android) {
      if (blockingEnabled) return 'Blocking active (${blockedApps.length} apps)';
      if (hasAndroidPermissions) return 'Permissions granted — ready to block';
      return 'Usage Access + Accessibility permissions required';
    }
    return message;
  }
}

enum FocusPlatform { android, ios, web, unknown }

class FocusProtectionService {
  static const _channel = MethodChannel('com.nora.nora_app/focus_protection');

  /// Get current platform and authorization status.
  Future<FocusProtectionStatus> getStatus() async {
    if (kIsWeb) return FocusProtectionStatus.unsupported;
    try {
      final result =
          await _channel.invokeMethod<Map<dynamic, dynamic>>('getStatus');
      return result == null
          ? FocusProtectionStatus.unsupported
          : FocusProtectionStatus.fromMap(result);
    } on PlatformException catch (error) {
      return FocusProtectionStatus(
        supported: false,
        authorized: false,
        usageAccessGranted: false,
        accessibilityGranted: false,
        blockingEnabled: false,
        blockedApps: [],
        message: error.message ?? 'Focus protection is unavailable.',
        platform: FocusProtectionStatus._detectPlatform(),
      );
    }
  }

  /// Request platform-specific authorization.
  ///
  /// Android: Opens Usage Access + Accessibility settings.
  /// iOS: Opens Screen Time settings / FamilyActivityPicker.
  Future<FocusProtectionStatus> requestAuthorization() async {
    if (kIsWeb) return FocusProtectionStatus.unsupported;
    try {
      final result = await _channel
          .invokeMethod<Map<dynamic, dynamic>>('requestAuthorization');
      return result == null
          ? FocusProtectionStatus.unsupported
          : FocusProtectionStatus.fromMap(result);
    } on PlatformException catch (error) {
      return FocusProtectionStatus(
        supported: false,
        authorized: false,
        usageAccessGranted: false,
        accessibilityGranted: false,
        blockingEnabled: false,
        blockedApps: [],
        message: error.message ?? 'Focus protection authorization failed.',
        platform: FocusProtectionStatus._detectPlatform(),
      );
    }
  }

  /// Open platform-specific settings page.
  Future<void> openSettings() async {
    if (kIsWeb) return;
    await _channel.invokeMethod<void>('openSettings');
  }

  /// iOS-only: Select app categories via FamilyActivityPicker.
  ///
  /// On Android, this is a no-op — use setBlockedApps instead.
  Future<FocusProtectionStatus> selectApps() async {
    if (kIsWeb) return FocusProtectionStatus.unsupported;
    if (Platform.isAndroid) {
      // Android uses package names, not categories.
      return getStatus();
    }
    final result =
        await _channel.invokeMethod<Map<dynamic, dynamic>>('selectApps');
    return result == null
        ? FocusProtectionStatus.unsupported
        : FocusProtectionStatus.fromMap(result);
  }

  /// Set the complete list of blocked apps.
  ///
  /// Android: Takes package names (e.g., "com.instagram.android").
  /// iOS: Not used — categories are set via selectApps / FamilyActivityPicker.
  Future<FocusProtectionStatus> setBlockedApps(List<String> packageIds) async {
    if (kIsWeb) return FocusProtectionStatus.unsupported;
    if (Platform.isIOS) {
      // iOS blocking goes through Screen Time categories, not package names.
      return getStatus();
    }
    final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
      'setBlockedPackages',
      packageIds,
    );
    return result == null
        ? FocusProtectionStatus.unsupported
        : FocusProtectionStatus.fromMap(result);
  }

  /// Enable blocking overlay.
  Future<FocusProtectionStatus> enableBlocking() async {
    if (kIsWeb) return FocusProtectionStatus.unsupported;
    final result =
        await _channel.invokeMethod<Map<dynamic, dynamic>>('enableBlocking');
    return result == null
        ? FocusProtectionStatus.unsupported
        : FocusProtectionStatus.fromMap(result);
  }

  /// Disable blocking overlay.
  Future<FocusProtectionStatus> disableBlocking() async {
    if (kIsWeb) return FocusProtectionStatus.unsupported;
    final result =
        await _channel.invokeMethod<Map<dynamic, dynamic>>('disableBlocking');
    return result == null
        ? FocusProtectionStatus.unsupported
        : FocusProtectionStatus.fromMap(result);
  }

  /// Check if Android "restricted settings" apply (sideloaded app).
  /// On Android 13+, sideloaded apps need special handling for
  /// AccessibilityService. This shows the disclosure UI.
  Future<bool> isRestrictedSettings() async {
    if (kIsWeb || Platform.isIOS) return false;
    try {
      final result = await _channel.invokeMethod<bool>('isRestrictedSettings');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Show Android disclosure dialog explaining why Accessibility is needed.
  /// This is required for Google Play Store submission.
  Future<void> showDisclosureDialog() async {
    if (kIsWeb || Platform.isIOS) return;
    await _channel.invokeMethod<void>('showDisclosureDialog');
  }
}
