import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/app_info.dart';

/// UsageTrackerService — Flutter bridge to the Android UsageTracker.
/// Tracks per-app usage time and provides usage analytics.
class UsageTrackerService {
  static const _channel = MethodChannel('com.nora.nora_app/usage_tracker');

  /// Get usage stats for the specified number of days back.
  Future<UsageStatsSummary?> getUsageStats({int daysBack = 7}) async {
    if (kIsWeb) return null;
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'getUsageStats',
        daysBack,
      );
      if (result == null) return null;

      final success = result['success'] == true;
      if (!success) return null;

      return UsageStatsSummary.fromMap(result);
    } on PlatformException catch (e) {
      debugPrint('UsageTracker getUsageStats failed: ${e.message}');
      return null;
    }
  }

  /// Get today's usage summary.
  Future<UsageStatsSummary?> getTodayUsage() async {
    if (kIsWeb) return null;
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>('getTodayUsage');
      if (result == null) return null;

      final success = result['success'] == true;
      if (!success) return null;

      return UsageStatsSummary.fromMap(result);
    } on PlatformException catch (e) {
      debugPrint('UsageTracker getTodayUsage failed: ${e.message}');
      return null;
    }
  }

  /// Get usage for a specific app.
  Future<Map<String, dynamic>> getAppUsage(String packageName, {int daysBack = 7}) async {
    if (kIsWeb) return {'success': false};
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'getAppUsage',
        {'packageName': packageName, 'daysBack': daysBack},
      );
      if (result == null) return {'success': false};

      return Map<String, dynamic>.from(result);
    } on PlatformException catch (e) {
      debugPrint('UsageTracker getAppUsage failed: ${e.message}');
      return {'success': false, 'error': e.message};
    }
  }

  /// Build a context string from usage data for AI analysis.
  /// This summarizes the user's device usage for the AI classifier.
  Future<String> buildUsageContextForAI() async {
    final todayUsage = await getTodayUsage();
    if (todayUsage == null) return 'No usage data available.';

    final buffer = StringBuffer();
    buffer.writeln('=== DEVICE USAGE TODAY ===');
    buffer.writeln('Total screen time: ${todayUsage.totalScreenTimeDisplay}');
    buffer.writeln('Social media time: ${todayUsage.socialMediaTimeDisplay}');
    buffer.writeln('Entertainment time: ${todayUsage.entertainmentMinutes}m');
    buffer.writeln('Productivity time: ${todayUsage.productivityMinutes}m');
    buffer.writeln('Apps used: ${todayUsage.appCount}');
    buffer.writeln();
    buffer.writeln('Top apps by usage:');
    for (final app in todayUsage.topApps.take(15)) {
      buffer.writeln('  - ${app.appName} (${app.category}): ${app.usageDisplay}');
    }

    return buffer.toString();
  }

  /// Build app list context for AI classification.
  Future<String> buildAppListContextForAI(List<AppInfo> apps) async {
    final buffer = StringBuffer();
    buffer.writeln('=== INSTALLED APPS (${apps.length} total) ===');

    final byCategory = <String, List<AppInfo>>{};
    for (final app in apps) {
      if (app.isSystemApp) continue;
      byCategory.putIfAbsent(app.category, () => []).add(app);
    }

    for (final entry in byCategory.entries) {
      buffer.writeln();
      buffer.writeln('${entry.key.toUpperCase()} (${entry.value.length} apps):');
      for (final app in entry.value) {
        buffer.writeln('  - ${app.appName} (${app.packageName})');
      }
    }

    return buffer.toString();
  }
}
