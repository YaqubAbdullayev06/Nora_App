import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/app_info.dart';
import 'screentime_service.dart';
import 'app_scanner_service.dart';
import 'llm_service.dart';

/// ProactiveAssistService — Background AI that monitors usage
/// and generates smart suggestions, alerts, and insights.
class ProactiveAssistService {
  static final ProactiveAssistService _instance = ProactiveAssistService._internal();
  factory ProactiveAssistService() => _instance;
  ProactiveAssistService._internal();

  final ScreenTimeService _usageService = ScreenTimeService();
  final AppScannerService _scannerService = AppScannerService();
  final LlmService _llmService = LlmService();

  Timer? _monitorTimer;
  final List<AssistNotification> _notifications = [];
  final StreamController<List<AssistNotification>> _notificationController =
      StreamController<List<AssistNotification>>.broadcast();

  Stream<List<AssistNotification>> get notificationStream =>
      _notificationController.stream;
  List<AssistNotification> get notifications => List.unmodifiable(_notifications);

  /// Start monitoring usage in the background.
  void startMonitoring({Duration interval = const Duration(minutes: 15)}) {
    _monitorTimer?.cancel();
    _monitorTimer = Timer.periodic(interval, (_) => _checkUsageAndGenerateInsights());
    // Run immediately on start
    _checkUsageAndGenerateInsights();
  }

  /// Stop monitoring.
  void stopMonitoring() {
    _monitorTimer?.cancel();
    _monitorTimer = null;
  }

  /// Get today's smart summary for the home screen.
  Future<SmartSummary> getTodaySummary() async {
    final todayUsage = await _usageService.getTodayUsage();
    if (todayUsage == null) {
      return SmartSummary.empty();
    }

    final blockedApps = await _scannerService.getBlockedApps();

    // Generate smart suggestions
    final suggestions = <String>[];
    final alerts = <String>[];

    // Social media check
    if (todayUsage.socialMediaMinutes > 120) {
      alerts.add('You\'ve spent ${todayUsage.socialMediaMinutes}m on social media today. Consider taking a break.');
    } else if (todayUsage.socialMediaMinutes > 60) {
      suggestions.add('Social media usage is at ${todayUsage.socialMediaMinutes}m. Try setting a 30m limit.');
    }

    // Screen time check
    if (todayUsage.totalScreenTimeMinutes > 240) {
      alerts.add('Total screen time is ${todayUsage.totalScreenTimeDisplay}. That\'s quite a lot!');
    } else if (todayUsage.totalScreenTimeMinutes > 120) {
      suggestions.add('You\'ve been on your phone for ${todayUsage.totalScreenTimeDisplay} today.');
    }

    // Productivity check
    if (todayUsage.productivityMinutes == 0 && todayUsage.totalScreenTimeMinutes > 60) {
      suggestions.add('No productivity apps used today. Maybe spend some time on learning?');
    }

    // Top distraction
    final topDistraction = todayUsage.topApps
        .where((a) => a.category == 'social_media' || a.category == 'entertainment')
        .firstOrNull;
    if (topDistraction != null && topDistraction.totalTimeMinutes > 30) {
      suggestions.add('${topDistraction.appName} is your biggest distraction today (${topDistraction.usageDisplay}).');
    }

    // Positive reinforcement
    if (todayUsage.totalScreenTimeMinutes < 30) {
      suggestions.add('Amazing! Low screen time today. Keep it up!');
    }
    if (todayUsage.productivityMinutes > todayUsage.socialMediaMinutes &&
        todayUsage.totalScreenTimeMinutes > 0) {
      suggestions.add('Great balance! More productive time than social media.');
    }

    // Calculate focus score
    int focusScore = 100;
    if (todayUsage.totalScreenTimeMinutes > 0) {
      final distractionRatio = (todayUsage.socialMediaMinutes + todayUsage.entertainmentMinutes) /
          todayUsage.totalScreenTimeMinutes;
      focusScore = (100 - (distractionRatio * 100)).round().clamp(0, 100);
    }

    return SmartSummary(
      totalScreenTime: todayUsage.totalScreenTimeDisplay,
      socialMediaTime: todayUsage.socialMediaTimeDisplay,
      topApps: todayUsage.topApps.take(5).toList(),
      suggestions: suggestions,
      alerts: alerts,
      blockedAppsCount: blockedApps.length,
      focusScore: focusScore,
    );
  }

  /// Check usage and generate insights periodically.
  Future<void> _checkUsageAndGenerateInsights() async {
    try {
      final todayUsage = await _usageService.getTodayUsage();
      if (todayUsage == null) return;

      final newNotifications = <AssistNotification>[];

      // Alert on excessive social media
      if (todayUsage.socialMediaMinutes > 120) {
        newNotifications.add(AssistNotification(
          id: 'social_alert_${DateTime.now().hour}',
          type: NotificationType.alert,
          title: 'Social Media Alert',
          message: 'You\'ve spent ${todayUsage.socialMediaTimeDisplay} on social media today.',
          action: 'Block social media apps?',
          timestamp: DateTime.now(),
        ));
      }

      // Suggestion on high screen time
      if (todayUsage.totalScreenTimeMinutes > 180) {
        newNotifications.add(AssistNotification(
          id: 'screen_time_${DateTime.now().hour}',
          type: NotificationType.suggestion,
          title: 'Screen Time Warning',
          message: 'Total screen time: ${todayUsage.totalScreenTimeDisplay}. Consider a break.',
          action: 'Start focus session?',
          timestamp: DateTime.now(),
        ));
      }

      // Add new notifications (avoid duplicates)
      for (final notif in newNotifications) {
        if (!_notifications.any((n) => n.id == notif.id)) {
          _notifications.add(notif);
        }
      }

      // Keep only last 20 notifications
      if (_notifications.length > 20) {
        _notifications.removeRange(0, _notifications.length - 20);
      }

      _notificationController.add(_notifications);
    } catch (e) {
      debugPrint('ProactiveAssist check failed: $e');
    }
  }

  /// Generate AI-powered usage analysis.
  Future<String> getAIInsight(String ageGroup) async {
    final contextData = await _buildContextForAI();
    final response = await _llmService.sendCommand(
      command: 'Analyze my device usage and give me one actionable insight to improve my focus.',
      ageGroup: ageGroup,
      context: contextData,
    );
    return response.response;
  }

  Future<Map<String, dynamic>> _buildContextForAI() async {
    final context = <String, dynamic>{};

    try {
      final todayUsage = await _usageService.getTodayUsage();
      if (todayUsage != null) {
        context['usage_today'] = {
          'totalScreenTimeMinutes': todayUsage.totalScreenTimeMinutes,
          'socialMediaMinutes': todayUsage.socialMediaMinutes,
          'entertainmentMinutes': todayUsage.entertainmentMinutes,
          'productivityMinutes': todayUsage.productivityMinutes,
        };
      }
    } catch (_) {}

    try {
      final blocked = await _scannerService.getBlockedApps();
      context['blocked_apps'] = blocked;
    } catch (_) {}

    return context;
  }

  /// Dismiss a notification.
  void dismissNotification(String id) {
    _notifications.removeWhere((n) => n.id == id);
    _notificationController.add(_notifications);
  }

  /// Clear all notifications.
  void clearNotifications() {
    _notifications.clear();
    _notificationController.add(_notifications);
  }

  /// Dispose resources.
  void dispose() {
    stopMonitoring();
    _notificationController.close();
  }
}

/// Smart summary for the home screen.
class SmartSummary {
  final String totalScreenTime;
  final String socialMediaTime;
  final List<AppUsageEntry> topApps;
  final List<String> suggestions;
  final List<String> alerts;
  final int blockedAppsCount;
  final int focusScore;

  const SmartSummary({
    required this.totalScreenTime,
    required this.socialMediaTime,
    required this.topApps,
    required this.suggestions,
    required this.alerts,
    required this.blockedAppsCount,
    required this.focusScore,
  });

  factory SmartSummary.empty() {
    return const SmartSummary(
      totalScreenTime: '0m',
      socialMediaTime: '0m',
      topApps: [],
      suggestions: ['Start your day by scanning your apps!'],
      alerts: [],
      blockedAppsCount: 0,
      focusScore: 100,
    );
  }

  bool get hasAlerts => alerts.isNotEmpty;
  bool get hasSuggestions => suggestions.isNotEmpty;
}

/// Notification types.
enum NotificationType { alert, suggestion, insight, achievement }

/// A single proactive notification.
class AssistNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final String? action;
  final DateTime timestamp;

  const AssistNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    this.action,
    required this.timestamp,
  });

  IconData get typeIcon {
    switch (type) {
      case NotificationType.alert:
        return Icons.warning_rounded;
      case NotificationType.suggestion:
        return Icons.lightbulb_rounded;
      case NotificationType.insight:
        return Icons.analytics_rounded;
      case NotificationType.achievement:
        return Icons.emoji_events_rounded;
    }
  }
}
