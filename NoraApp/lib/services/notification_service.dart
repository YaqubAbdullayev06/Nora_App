import 'dart:async';
import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:rxdart/rxdart.dart';
import 'package:http/http.dart' as http;
import '../core/config/env_config.dart';
import 'api_service.dart';

/// Notification types for different app events.
enum NotificationType {
  focusStart,
  focusEnd,
  focusBreak,
  habitReminder,
  hardCapWarning,
  hardCapReached,
  accountabilityAlert,
  dailyMotivation,
  sessionComplete,
  custom,
}

/// AI-generated notification text service.
/// Uses the backend LLM to generate contextual, personalized alert messages.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// Stream of notification taps (for handling in-app navigation).
  final BehaviorSubject<NotificationResponse> _onNotificationTapped =
      BehaviorSubject<NotificationResponse>.seeded(
    const NotificationResponse(
      notificationResponseType:
          NotificationResponseType.selectedNotification,
      payload: '',
    ),
  );
  Stream<NotificationResponse> get onNotificationTapped =>
      _onNotificationTapped.stream;

  bool _isInitialized = false;

  // ─── AI Notification Text Cache ───
  // Cache AI-generated texts to avoid repeated API calls
  final Map<String, String> _textCache = {};

  /// Initialize the notification service.
  Future<void> init() async {
    if (_isInitialized) return;

    // Initialize timezone database
    tz.initializeTimeZones();

    // Android settings
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        _onNotificationTapped.add(response);
      },
    );

    _isInitialized = true;
  }

  // ─── Permission Requests ───

  /// Request notification permission (iOS).
  Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final granted = await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    return true; // Default for other platforms
  }

  // ─── AI Text Generation ───

  /// Get AI-generated notification text from the backend.
  /// Falls back to default text if the API call fails.
  Future<String> _getAiText({
    required String eventType,
    required String ageGroup,
    Map<String, dynamic>? context,
  }) async {
    final cacheKey = '${eventType}_${ageGroup}_${context.hashCode}';
    if (_textCache.containsKey(cacheKey)) {
      return _textCache[cacheKey]!;
    }

    try {
      final baseUrl = EnvConfig.instance.backendUrl;
      final response = await http
          .post(
            Uri.parse('$baseUrl/ai/notification-text'),
            headers: ApiService().authHeaders,
            body: jsonEncode({
              'event_type': eventType,
              'age_group': ageGroup,
              'context': context ?? {},
            }),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['text'] as String? ?? _getDefaultText(eventType);
        _textCache[cacheKey] = text;
        return text;
      }
    } catch (_) {
      // API failed — use default
    }

    return _getDefaultText(eventType);
  }

  /// Fallback notification texts when AI is unavailable.
  String _getDefaultText(String eventType) {
    switch (eventType) {
      case 'focus_start':
        return "Time to focus! Your session starts now.";
      case 'focus_end':
        return "Great work! Your focus session is complete.";
      case 'focus_break':
        return "Break time! Stretch and recharge.";
      case 'habit_reminder':
        return "Don't forget your daily habits!";
      case 'hard_cap_warning':
        return "Heads up — you're approaching your screen time limit.";
      case 'hard_cap_reached':
        return "You've reached your daily screen time cap.";
      case 'accountability_alert':
        return "Accountability check: stay on track!";
      case 'daily_motivation':
        return "Today is a new opportunity to focus and grow.";
      case 'session_complete':
        return "Session complete! Keep up the great work.";
      default:
        return "Nora has an update for you.";
    }
  }

  // ─── Instant Notifications ───

  /// Show an instant notification with AI-generated text.
  Future<void> showAlert({
    required NotificationType type,
    required String ageGroup,
    Map<String, dynamic>? context,
    String? customTitle,
    int id = 0,
  }) async {
    if (!_isInitialized) await init();

    final eventType = _typeToEvent(type);
    final body = await _getAiText(
      eventType: eventType,
      ageGroup: ageGroup,
      context: context,
    );
    final title = customTitle ?? 'Nora';

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'nora_alerts',
        'Nora Alerts',
        channelDescription: 'Alert notifications from Nora',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        styleInformation: BigTextStyleInformation(body),
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _plugin.show(id, title, body, details, payload: eventType);
  }

  // ─── Scheduled Notifications ───

  /// Schedule a notification at a specific time.
  Future<void> scheduleAlert({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    if (!_isInitialized) await init();

    final tzDateTime = tz.TZDateTime.from(scheduledTime, tz.local);

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'nora_scheduled',
        'Nora Scheduled',
        channelDescription: 'Scheduled notifications from Nora',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tzDateTime,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: null,
      payload: payload,
    );
  }

  /// Schedule a recurring daily notification with AI text.
  Future<void> scheduleDailyMotivation({
    required int hour,
    required int minute,
    required String ageGroup,
  }) async {
    if (!_isInitialized) await init();

    final body = await _getAiText(
      eventType: 'daily_motivation',
      ageGroup: ageGroup,
    );

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'nora_daily',
        'Daily Motivation',
        channelDescription: 'Daily motivational messages from Nora',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: false,
        presentSound: true,
      ),
    );

    await _plugin.zonedSchedule(
      9999, // Fixed ID for daily motivation
      'Nora',
      body,
      _nextInstanceOfTime(hour, minute),
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'daily_motivation',
    );
  }

  /// Schedule habit reminder notifications.
  Future<void> scheduleHabitReminder({
    required int id,
    required String habitName,
    required int hour,
    required int minute,
    required String ageGroup,
  }) async {
    if (!_isInitialized) await init();

    final body = await _getAiText(
      eventType: 'habit_reminder',
      ageGroup: ageGroup,
      context: {'habit_name': habitName},
    );

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'nora_habits',
        'Habit Reminders',
        channelDescription: 'Reminders for your daily habits',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: false,
        presentSound: true,
      ),
    );

    await _plugin.zonedSchedule(
      id,
      'Habit Reminder',
      body,
      _nextInstanceOfTime(hour, minute),
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'habit_reminder',
    );
  }

  // ─── Cancel ───

  /// Cancel a specific notification.
  Future<void> cancel(int id) async {
    await _plugin.cancel(id);
  }

  /// Cancel all notifications.
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  // ─── Helpers ───

  String _typeToEvent(NotificationType type) {
    switch (type) {
      case NotificationType.focusStart:
        return 'focus_start';
      case NotificationType.focusEnd:
        return 'focus_end';
      case NotificationType.focusBreak:
        return 'focus_break';
      case NotificationType.habitReminder:
        return 'habit_reminder';
      case NotificationType.hardCapWarning:
        return 'hard_cap_warning';
      case NotificationType.hardCapReached:
        return 'hard_cap_reached';
      case NotificationType.accountabilityAlert:
        return 'accountability_alert';
      case NotificationType.dailyMotivation:
        return 'daily_motivation';
      case NotificationType.sessionComplete:
        return 'session_complete';
      case NotificationType.custom:
        return 'custom';
    }
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
