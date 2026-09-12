import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/app_info.dart';

/// AppScannerService — Flutter bridge to the platform-specific app scanner.
///
/// PLATFORM ABSTRACTION:
/// - Android: Uses AccessibilityService to scan all installed apps by package name.
///   Requires Permissions Declaration Form for Play Store. Must handle "restricted
///   settings" on Android 13+ for sideloaded installs.
/// - iOS: Uses Screen Time API with FamilyActivityPicker. Apps are represented as
///   opaque ApplicationTokens — you CANNOT resolve to bundle ID or human-readable
///   name. Classification happens by category within the picker, not by scanning
///   all apps. AI advises on aggregate patterns rather than named apps.
class AppScannerService {
  static final AppScannerService _instance = AppScannerService._internal();
  factory AppScannerService() => _instance;
  AppScannerService._internal();

  static const _channel = MethodChannel('com.nora.nora_app/app_scanner');

  /// Check the current platform's scanning capabilities.
  Future<PlatformScanCapability> getPlatformCapability() async {
    if (kIsWeb) return PlatformScanCapability.web;
    if (Platform.isIOS) return PlatformScanCapability.ios;
    if (Platform.isAndroid) return PlatformScanCapability.android;
    return PlatformScanCapability.unknown;
  }

  /// Scan all installed apps on the device.
  ///
  /// On Android: Returns full app list with package names and metadata.
  /// On iOS: Returns empty list — iOS uses FamilyActivityPicker instead.
  ///         Use [selectIOSCategories] for iOS app selection.
  Future<List<AppInfo>> scanAllApps() async {
    if (kIsWeb) return [];
    if (Platform.isIOS) {
      // iOS cannot scan all apps. Must use FamilyActivityPicker.
      return [];
    }
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>('scanAllApps');
      if (result == null) return [];

      final success = result['success'] == true;
      if (!success) return [];

      final apps = (result['apps'] as List<dynamic>? ?? [])
          .map((app) => AppInfo.fromMap(Map<String, dynamic>.from(app as Map)))
          .toList();
      return apps;
    } on PlatformException catch (e) {
      debugPrint('AppScanner scanAllApps failed: ${e.message}');
      return [];
    }
  }

  /// iOS-only: Select app categories via FamilyActivityPicker.
  ///
  /// On iOS, apps are represented as opaque ApplicationTokens.
  /// You cannot resolve them to bundle IDs or names.
  /// The picker returns categories (social, entertainment, etc.)
  /// and aggregate usage data — NOT individual app names.
  Future<List<String>> selectIOSCategories() async {
    if (!Platform.isIOS) return [];
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>('selectIOSCategories');
      if (result == null) return [];

      final categories = (result['categories'] as List<dynamic>? ?? [])
          .map((item) => item.toString())
          .toList();
      return categories;
    } on PlatformException catch (e) {
      debugPrint('AppScanner selectIOSCategories failed: ${e.message}');
      return [];
    }
  }

  /// Get detailed info for a specific app (Android only).
  Future<AppInfo?> getAppDetails(String packageName) async {
    if (kIsWeb || Platform.isIOS) return null;
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'getAppDetails',
        packageName,
      );
      if (result == null) return null;

      final success = result['success'] == true;
      if (!success) return null;

      final app = result['app'];
      if (app == null) return null;
      return AppInfo.fromMap(Map<String, dynamic>.from(app as Map));
    } on PlatformException catch (e) {
      debugPrint('AppScanner getAppDetails failed: ${e.message}');
      return null;
    }
  }

  /// Get the current list of blocked apps.
  Future<List<String>> getBlockedApps() async {
    if (kIsWeb) return [];
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>('getBlockedApps');
      if (result == null) return [];

      final blocked = (result['blockedApps'] as List<dynamic>? ?? [])
          .map((item) => item.toString())
          .toList();
      return blocked;
    } on PlatformException catch (e) {
      debugPrint('AppScanner getBlockedApps failed: ${e.message}');
      return [];
    }
  }

  /// Set the complete blocked apps list.
  Future<List<String>> setBlockedApps(List<String> packageIds) async {
    if (kIsWeb) return [];
    if (Platform.isIOS) {
      // iOS blocking goes through Screen Time API, not package names.
      // Return empty — use selectIOSCategories instead.
      return [];
    }
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'setBlockedApps',
        packageIds,
      );
      if (result == null) return [];

      final blocked = (result['blockedApps'] as List<dynamic>? ?? [])
          .map((item) => item.toString())
          .toList();
      return blocked;
    } on PlatformException catch (e) {
      debugPrint('AppScanner setBlockedApps failed: ${e.message}');
      return [];
    }
  }

  /// Add apps to the block list.
  Future<List<String>> addToBlockedApps(List<String> packageIds) async {
    if (kIsWeb) return [];
    if (Platform.isIOS) return [];
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'addToBlocked',
        packageIds,
      );
      if (result == null) return [];

      final blocked = (result['blockedApps'] as List<dynamic>? ?? [])
          .map((item) => item.toString())
          .toList();
      return blocked;
    } on PlatformException catch (e) {
      debugPrint('AppScanner addToBlocked failed: ${e.message}');
      return [];
    }
  }

  /// Remove apps from the block list.
  Future<List<String>> removeFromBlockedApps(List<String> packageIds) async {
    if (kIsWeb) return [];
    if (Platform.isIOS) return [];
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'removeFromBlocked',
        packageIds,
      );
      if (result == null) return [];

      final blocked = (result['blockedApps'] as List<dynamic>? ?? [])
          .map((item) => item.toString())
          .toList();
      return blocked;
    } on PlatformException catch (e) {
      debugPrint('AppScanner removeFromBlocked failed: ${e.message}');
      return [];
    }
  }

  /// Scan apps and merge with current blocked list.
  Future<List<AppInfo>> scanAppsWithBlockStatus() async {
    final apps = await scanAllApps();
    final blocked = await getBlockedApps();
    final blockedSet = blocked.toSet();

    return apps.map((app) {
      return app.copyWith(isBlocked: blockedSet.contains(app.packageName));
    }).toList();
  }

  /// Get app icon as base64 string.
  Future<String?> getAppIcon(String packageName) async {
    if (kIsWeb || Platform.isIOS) return null;
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'getAppIcon',
        packageName,
      );
      if (result == null) return null;
      final success = result['success'] == true;
      if (!success) return null;
      return result['icon'] as String?;
    } on PlatformException catch (e) {
      debugPrint('AppScanner getAppIcon failed: ${e.message}');
      return null;
    }
  }
}

/// Platform-specific scanning capability.
enum PlatformScanCapability {
  android,   // Full app scanning by package name via AccessibilityService
  ios,       // FamilyActivityPicker only — opaque tokens, no package names
  web,       // No native scanning
  unknown,
}
