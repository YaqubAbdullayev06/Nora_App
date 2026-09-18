import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/enums/age_group.dart';
import '../models/models.dart';
import '../services/notification_service.dart';
import 'persona_provider.dart';

/// Manages focus scores, sessions history, streaks, and achievements.
/// Sessions are persisted to secure storage so they survive app restarts.
class FocusProvider extends ChangeNotifier {
  final PersonaProvider _personaProvider;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const _sessionsKey = 'nora_focus_sessions';
  static const _statsKey = 'nora_focus_stats';

  int _focusScore = 0;
  int _totalFocusMinutes = 0;
  int _streakDays = 0;
  int _sessionsCompleted = 0;
  List<String> _achievements = [];
  List<FocusSession> _sessions = [];

  FocusProvider({required PersonaProvider personaProvider})
      : _personaProvider = personaProvider;

  int get focusScore => _focusScore;
  int get totalFocusMinutes => _totalFocusMinutes;
  int get streakDays => _streakDays;
  int get sessionsCompleted => _sessionsCompleted;
  List<String> get achievements => _achievements;
  List<FocusSession> get sessions => _sessions;

  /// Load persisted sessions and stats from secure storage.
  Future<void> load() async {
    // Load sessions
    final sessionsJson = await _storage.read(key: _sessionsKey);
    if (sessionsJson != null && sessionsJson.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(sessionsJson);
        _sessions = decoded.map((e) => FocusSession.fromJson(e)).toList();
      } catch (_) {
        _sessions = [];
      }
    }

    // Load aggregated stats
    final statsJson = await _storage.read(key: _statsKey);
    if (statsJson != null && statsJson.isNotEmpty) {
      try {
        final stats = jsonDecode(statsJson) as Map<String, dynamic>;
        _focusScore = stats['focusScore'] ?? 0;
        _totalFocusMinutes = stats['totalFocusMinutes'] ?? 0;
        _sessionsCompleted = stats['sessionsCompleted'] ?? 0;
        _achievements = List<String>.from(stats['achievements'] ?? []);
      } catch (_) {}
    }

    // Recompute streak from persisted sessions
    _streakDays = computedStreakDays;
    notifyListeners();
  }

  /// Persist sessions and stats to secure storage.
  Future<void> _persist() async {
    // Cap stored sessions to last 200 to avoid storage limits
    final toStore = _sessions.length > 200
        ? _sessions.sublist(_sessions.length - 200)
        : _sessions;
    await _storage.write(
      key: _sessionsKey,
      value: jsonEncode(toStore.map((s) => s.toJson()).toList()),
    );
    await _storage.write(
      key: _statsKey,
      value: jsonEncode({
        'focusScore': _focusScore,
        'totalFocusMinutes': _totalFocusMinutes,
        'sessionsCompleted': _sessionsCompleted,
        'achievements': _achievements,
      }),
    );
  }

  List<int> get weeklyFocusMinutes {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

    final List<int> minutes = List.filled(7, 0);
    for (final session in _sessions) {
      if (!session.completed) continue;
      final sessionDate = DateTime(
        session.startTime.year,
        session.startTime.month,
        session.startTime.day,
      );
      final dayIndex = sessionDate.difference(startOfWeek).inDays;
      if (dayIndex >= 0 && dayIndex < 7) {
        minutes[dayIndex] += session.durationMinutes;
      }
    }
    return minutes;
  }

  int get computedStreakDays {
    if (_sessions.isEmpty) return 0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final completedDates = _sessions
        .where((s) => s.completed)
        .map((s) =>
            DateTime(s.startTime.year, s.startTime.month, s.startTime.day))
        .toSet()
      ..removeWhere((d) => d.isAfter(today));

    if (completedDates.isEmpty) return 0;

    final yesterday = today.subtract(const Duration(days: 1));
    if (!completedDates.contains(today) &&
        !completedDates.contains(yesterday)) {
      return 0;
    }

    int streak = 0;
    DateTime checkDate = completedDates.contains(today) ? today : yesterday;
    while (completedDates.contains(checkDate)) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// Record a completed focus session and update scores/streaks.
  void recordSession(FocusSession session) {
    _sessions.add(session);

    _focusScore += session.pointsEarned;
    _totalFocusMinutes += session.durationMinutes;
    _sessionsCompleted++;
    _streakDays = computedStreakDays;

    _checkAchievements();
    _persist(); // persist asynchronously — don't block UI
    notifyListeners();

    // Send AI notification for session complete
    NotificationService().showAlert(
      type: NotificationType.sessionComplete,
      ageGroup: _personaProvider.ageGroup.name,
      context: {
        'duration': session.durationMinutes,
        'points': session.pointsEarned,
      },
    );
  }

  void addFocusTime(int minutes) {
    final points =
        (minutes * 10 * _personaProvider.ageGroup.pointsMultiplier).toInt();
    final now = DateTime.now();
    _sessions.add(FocusSession(
      id: 'session_${now.millisecondsSinceEpoch}',
      startTime: now.subtract(Duration(minutes: minutes)),
      endTime: now,
      durationMinutes: minutes,
      pointsEarned: points,
      completed: true,
    ));

    _totalFocusMinutes += minutes;
    _focusScore += points;
    _sessionsCompleted++;
    _streakDays = computedStreakDays;
    _checkAchievements();
    _persist();
    notifyListeners();

    // Send AI notification for session complete
    NotificationService().showAlert(
      type: NotificationType.sessionComplete,
      ageGroup: _personaProvider.ageGroup.name,
      context: {'duration': minutes, 'points': points},
    );
  }

  void updateStreak(int days) {
    _streakDays = days;
    notifyListeners();
  }

  void addAchievement(String achievement) {
    if (!_achievements.contains(achievement)) {
      _achievements.add(achievement);
      notifyListeners();
    }
  }

  void _checkAchievements() {
    if (_sessionsCompleted >= 1 && !_achievements.contains('First Focus')) {
      _achievements.add('First Focus');
    }
    if (_streakDays >= 3 && !_achievements.contains('3-Day Streak')) {
      _achievements.add('3-Day Streak');
    }
    if (_totalFocusMinutes >= 60 && !_achievements.contains('Early Bird')) {
      _achievements.add('Early Bird');
    }
    if (_sessionsCompleted >= 10 && !_achievements.contains('Focus Master')) {
      _achievements.add('Focus Master');
    }
    if (_focusScore >= 1000 && !_achievements.contains('High Scorer')) {
      _achievements.add('High Scorer');
    }
    if (!_achievements.contains('Lifelong Learner') && _focusScore >= 2500) {
      _achievements.add('Lifelong Learner');
    }
  }

  void clearAll() {
    _focusScore = 0;
    _totalFocusMinutes = 0;
    _streakDays = 0;
    _sessionsCompleted = 0;
    _achievements = [];
    _sessions = [];
    _persist();
    notifyListeners();
  }
}
