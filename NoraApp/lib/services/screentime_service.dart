import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/app_info.dart';
import '../models/models.dart';

/// ScreenTimeService — Cross-platform screen time tracking.
///
/// Provides a unified API for tracking device usage across Android and iOS.
///
/// Platform Differences:
/// - Android: Uses UsageStatsManager for detailed per-app usage data.
///   Requires PACKAGE_USAGE_STATS permission + Usage Access in Settings.
///
/// - iOS: Uses DeviceActivity framework for category-based usage data.
///   Apps are opaque tokens — cannot resolve to bundle IDs or names.
///   Classification happens by category (social, entertainment, etc.)
///
/// - Web/Desktop: No native screen time tracking available.
class ScreenTimeService {
  static final ScreenTimeService _instance = ScreenTimeService._internal();
  factory ScreenTimeService() => _instance;
  ScreenTimeService._internal();

  static const _usageChannel = MethodChannel('com.nora.nora_app/usage_tracker');
  static const _focusChannel = MethodChannel('com.nora.nora_app/focus_protection');

  bool _isInitialized = false;
  ScreenTimePlatform _platform = ScreenTimePlatform.unknown;

  // ─── Initialization ───

  /// Initialize the service and detect platform capabilities.
  Future<void> initialize() async {
    if (_isInitialized) return;
    if (kIsWeb) {
      _platform = ScreenTimePlatform.web;
      return;
    }

    if (Platform.isAndroid) {
      _platform = ScreenTimePlatform.android;
    } else if (Platform.isIOS) {
      _platform = ScreenTimePlatform.ios;
    } else {
      _platform = ScreenTimePlatform.desktop;
    }

    _isInitialized = true;
    debugPrint('[ScreenTimeService] Initialized for $_platform');
  }

  /// Get the current platform.
  ScreenTimePlatform get platform => _platform;

  /// Check if screen time tracking is available on this platform.
  bool get isAvailable =>
      _platform == ScreenTimePlatform.android ||
      _platform == ScreenTimePlatform.ios;

  // ─── Permission Management ───

  /// Check if screen time permissions are granted.
  Future<ScreenTimePermission> checkPermission() async {
    if (!isAvailable) return ScreenTimePermission.unavailable;

    try {
      if (_platform == ScreenTimePlatform.android) {
        return await _checkAndroidPermission();
      } else if (_platform == ScreenTimePlatform.ios) {
        return await _checkIOSPermission();
      }
    } on PlatformException catch (e) {
      debugPrint('[ScreenTimeService] Permission check failed: ${e.message}');
    }

    return ScreenTimePermission.denied;
  }

  /// Request screen time permissions.
  Future<ScreenTimePermission> requestPermission() async {
    if (!isAvailable) return ScreenTimePermission.unavailable;

    try {
      if (_platform == ScreenTimePlatform.android) {
        return await _requestAndroidPermission();
      } else if (_platform == ScreenTimePlatform.ios) {
        return await _requestIOSPermission();
      }
    } on PlatformException catch (e) {
      debugPrint('[ScreenTimeService] Permission request failed: ${e.message}');
    }

    return ScreenTimePermission.denied;
  }

  Future<ScreenTimePermission> _checkAndroidPermission() async {
    final result = await _usageChannel.invokeMapMethod<String, dynamic>(
      'getUsageStats',
      1,
    );
    if (result == null) return ScreenTimePermission.denied;
    return result['success'] == true
        ? ScreenTimePermission.granted
        : ScreenTimePermission.denied;
  }

  Future<ScreenTimePermission> _requestAndroidPermission() async {
    // Android requires manual permission grant through Settings
    await _focusChannel.invokeMethod('openSettings');
    return ScreenTimePermission.settingsOpened;
  }

  Future<ScreenTimePermission> _checkIOSPermission() async {
    final result = await _usageChannel.invokeMapMethod<String, dynamic>(
      'getAuthorizationStatus',
    );
    if (result == null) return ScreenTimePermission.denied;
    final status = result['status'] as String? ?? '';
    return status.contains('approved')
        ? ScreenTimePermission.granted
        : ScreenTimePermission.denied;
  }

  Future<ScreenTimePermission> _requestIOSPermission() async {
    final result = await _usageChannel.invokeMapMethod<String, dynamic>(
      'requestAuthorization',
    );
    if (result == null) return ScreenTimePermission.denied;
    return result['success'] == true
        ? ScreenTimePermission.granted
        : ScreenTimePermission.denied;
  }

  // ─── Usage Data ───

  /// Get usage stats for the specified number of days back.
  Future<UsageStatsSummary?> getUsageStats({int daysBack = 7}) async {
    if (!isAvailable) return null;

    try {
      final result = await _usageChannel.invokeMapMethod<String, dynamic>(
        'getUsageStats',
        daysBack,
      );
      if (result == null) return null;
      if (result['success'] != true) return null;

      return UsageStatsSummary.fromMap(Map<String, dynamic>.from(result));
    } on PlatformException catch (e) {
      debugPrint('[ScreenTimeService] getUsageStats failed: ${e.message}');
      return null;
    }
  }

  /// Get today's usage summary.
  Future<UsageStatsSummary?> getTodayUsage() async {
    if (!isAvailable) return null;

    try {
      final result = await _usageChannel.invokeMapMethod<String, dynamic>(
        'getTodayUsage',
      );
      if (result == null) return null;
      if (result['success'] != true) return null;

      return UsageStatsSummary.fromMap(Map<String, dynamic>.from(result));
    } on PlatformException catch (e) {
      debugPrint('[ScreenTimeService] getTodayUsage failed: ${e.message}');
      return null;
    }
  }

  /// Get per-day top app usage for the current week (Mon–Sun).
  Future<List<WeeklyAppUsage>> getWeeklyAppUsage() async {
    if (!isAvailable) return List.generate(7, (i) => WeeklyAppUsage(
      dayIndex: i, appName: '', minutes: 0, category: '', iconPath: '',
    ));

    try {
      final result = await _usageChannel.invokeMapMethod<String, dynamic>(
        'getWeeklyAppUsage',
      );
      if (result == null || result['success'] != true) {
        return List.generate(7, (i) => WeeklyAppUsage(
          dayIndex: i, appName: '', minutes: 0, category: '', iconPath: '',
        ));
      }

      final days = (result['days'] as List<dynamic>? ?? []);
      return days.map((day) {
        final map = Map<String, dynamic>.from(day as Map);
        final appName = map['appName'] as String? ?? '';
        final category = map['category'] as String? ?? '';
        final iconPath = _iconPathForApp(appName, category);
        return WeeklyAppUsage(
          dayIndex: map['dayIndex'] as int? ?? 0,
          appName: appName,
          minutes: map['minutes'] as int? ?? 0,
          category: category,
          iconPath: iconPath,
        );
      }).toList();
    } on PlatformException catch (e) {
      debugPrint('[ScreenTimeService] getWeeklyAppUsage failed: ${e.message}');
      return List.generate(7, (i) => WeeklyAppUsage(
        dayIndex: i, appName: '', minutes: 0, category: '', iconPath: '',
      ));
    }
  }

  /// Maps app name / category to a local SVG icon path.
  String _iconPathForApp(String appName, String category) {
    final lower = appName.toLowerCase();
    if (lower.contains('instagram')) return 'assets/images/apps/instagram.svg';
    if (lower.contains('youtube')) return 'assets/images/apps/youtube.svg';
    if (lower.contains('whatsapp')) return 'assets/images/apps/whatsapp.svg';
    if (lower.contains('tiktok')) return 'assets/images/apps/tiktok.svg';
    if (lower.contains('telegram')) return 'assets/images/apps/telegram.svg';
    if (lower.contains('spotify')) return 'assets/images/apps/spotify.svg';
    if (lower.contains('chrome') || lower.contains('safari') || lower.contains('browser')) {
      return 'assets/images/apps/chrome.svg';
    }
    // Fallback: use a generic category-based icon
    return '';
  }

  /// Get usage for a specific app (Android only — iOS returns null).
  Future<Map<String, dynamic>?> getAppUsage(
    String packageName, {
    int daysBack = 7,
  }) async {
    if (_platform != ScreenTimePlatform.android) return null;

    try {
      final result = await _usageChannel.invokeMapMethod<String, dynamic>(
        'getAppUsage',
        {'packageName': packageName, 'daysBack': daysBack},
      );
      if (result == null) return null;
      return Map<String, dynamic>.from(result);
    } on PlatformException catch (e) {
      debugPrint('[ScreenTimeService] getAppUsage failed: ${e.message}');
      return null;
    }
  }

  // ─── Monitoring ───

  /// Start background usage monitoring.
  Future<bool> startMonitoring() async {
    if (!isAvailable) return false;

    try {
      final result = await _usageChannel.invokeMapMethod<String, dynamic>(
        'startMonitoring',
      );
      return result?['success'] == true;
    } on PlatformException catch (e) {
      debugPrint('[ScreenTimeService] startMonitoring failed: ${e.message}');
      return false;
    }
  }

  /// Stop background usage monitoring.
  Future<bool> stopMonitoring() async {
    if (!isAvailable) return false;

    try {
      final result = await _usageChannel.invokeMapMethod<String, dynamic>(
        'stopMonitoring',
      );
      return result?['success'] == true;
    } on PlatformException catch (e) {
      debugPrint('[ScreenTimeService] stopMonitoring failed: ${e.message}');
      return false;
    }
  }

  /// Check if monitoring is active.
  Future<bool> isMonitoring() async {
    if (!isAvailable) return false;

    try {
      final result = await _usageChannel.invokeMapMethod<String, dynamic>(
        'isMonitoring',
      );
      return result?['isMonitoring'] == true;
    } on PlatformException catch (e) {
      debugPrint('[ScreenTimeService] isMonitoring failed: ${e.message}');
      return false;
    }
  }

  // ─── AI Context ───

  /// Build a context string from usage data for AI analysis.
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

    if (_platform == ScreenTimePlatform.ios) {
      buffer.writeln('Note: iOS provides category-based usage data.');
      buffer.writeln('Individual app data is not available for privacy reasons.');
    } else {
      buffer.writeln('Top apps by usage:');
      for (final app in todayUsage.topApps.take(15)) {
        buffer.writeln('  - ${app.appName} (${app.category}): ${app.usageDisplay}');
      }
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

  // ─── Screen Time Insights ───

  /// Analyze usage patterns and provide insights.
  Future<ScreenTimeInsights> analyzeUsagePatterns() async {
    final weekUsage = await getUsageStats(daysBack: 7);
    final todayUsage = await getTodayUsage();

    if (weekUsage == null || todayUsage == null) {
      return ScreenTimeInsights.empty();
    }

    // Calculate daily average
    final dailyAverage = weekUsage.totalScreenTimeMinutes / 7;

    // Calculate distraction ratio
    final distractionRatio = weekUsage.distractionRatio;

    // Detect peak usage day (simplified)
    final isWeekendDetected = DateTime.now().weekday > 5;

    return ScreenTimeInsights(
      dailyAverageMinutes: dailyAverage.round(),
      todayMinutes: todayUsage.totalScreenTimeMinutes,
      weeklyTotalMinutes: weekUsage.totalScreenTimeMinutes,
      distractionRatio: distractionRatio,
      isHighUsageDay: todayUsage.totalScreenTimeMinutes > dailyAverage * 1.2,
      isHighDistractionDay: distractionRatio > 0.4,
      topCategories: _getTopCategories(weekUsage),
      recommendations: _generateRecommendations(
        todayMinutes: todayUsage.totalScreenTimeMinutes,
        dailyAverage: dailyAverage.round(),
        distractionRatio: distractionRatio,
      ),
    );
  }

  List<String> _getTopCategories(UsageStatsSummary usage) {
    final categories = <String, int>{
      'Social Media': usage.socialMediaMinutes,
      'Entertainment': usage.entertainmentMinutes,
      'Productivity': usage.productivityMinutes,
    };

    final sorted = categories.entries
        .where((e) => e.value > 0)
        .toList();
    sorted.sort((a, b) => b.value.compareTo(a.value));
    return sorted.map((e) => e.key).toList();
  }

  List<String> _generateRecommendations({
    required int todayMinutes,
    required int dailyAverage,
    required double distractionRatio,
  }) {
    final recommendations = <String>[];

    if (todayMinutes > dailyAverage * 1.5) {
      recommendations.add(
        'Your screen time today is significantly higher than usual. Consider taking a break.',
      );
    }

    if (distractionRatio > 0.5) {
      recommendations.add(
        'More than half your time is spent on social media or entertainment. Try focusing on productive tasks.',
      );
    }

    if (todayMinutes > 120) {
      recommendations.add(
        'You\'ve been using your device for over 2 hours. Time for a screen break!',
      );
    }

    if (recommendations.isEmpty) {
      recommendations.add('Your usage looks healthy. Keep it up!');
    }

    return recommendations;
  }
}

// ─── Data Classes ───

enum ScreenTimePlatform {
  android,
  ios,
  web,
  desktop,
  unknown,
}

enum ScreenTimePermission {
  granted,
  denied,
  restricted,
  settingsOpened,
  unavailable,
}

class ScreenTimeInsights {
  final int dailyAverageMinutes;
  final int todayMinutes;
  final int weeklyTotalMinutes;
  final double distractionRatio;
  final bool isHighUsageDay;
  final bool isHighDistractionDay;
  final List<String> topCategories;
  final List<String> recommendations;

  const ScreenTimeInsights({
    required this.dailyAverageMinutes,
    required this.todayMinutes,
    required this.weeklyTotalMinutes,
    required this.distractionRatio,
    required this.isHighUsageDay,
    required this.isHighDistractionDay,
    required this.topCategories,
    required this.recommendations,
  });

  factory ScreenTimeInsights.empty() {
    return const ScreenTimeInsights(
      dailyAverageMinutes: 0,
      todayMinutes: 0,
      weeklyTotalMinutes: 0,
      distractionRatio: 0,
      isHighUsageDay: false,
      isHighDistractionDay: false,
      topCategories: [],
      recommendations: ['No usage data available.'],
    );
  }

  String get dailyAverageDisplay {
    final hours = dailyAverageMinutes ~/ 60;
    final mins = dailyAverageMinutes % 60;
    if (hours > 0) return '${hours}h ${mins}m';
    return '${mins}m';
  }

  String get todayDisplay {
    final hours = todayMinutes ~/ 60;
    final mins = todayMinutes % 60;
    if (hours > 0) return '${hours}h ${mins}m';
    return '${mins}m';
  }

  String get distractionPercent => '${(distractionRatio * 100).round()}%';
}
