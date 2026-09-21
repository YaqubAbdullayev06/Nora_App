import 'package:flutter/foundation.dart';
import '../models/models.dart';
import 'focus_provider.dart';
import 'persona_provider.dart';

/// Manages weekly review state, reflections, and goals.
class WeeklyReviewProvider extends ChangeNotifier {
  final PersonaProvider _personaProvider;
  final FocusProvider _focusProvider;

  WeeklyReview? _currentWeeklyReview;
  List<WeeklyReview> _weeklyReviewHistory = [];

  WeeklyReviewProvider({
    required PersonaProvider personaProvider,
    required FocusProvider focusProvider,
  })  : _personaProvider = personaProvider,
        _focusProvider = focusProvider;

  WeeklyReview? get currentWeeklyReview => _currentWeeklyReview;
  List<WeeklyReview> get weeklyReviewHistory => _weeklyReviewHistory;

  DateTime get _currentWeekStart {
    final now = DateTime.now();
    return now.subtract(Duration(days: now.weekday - 1));
  }

  DateTime get _currentWeekEnd {
    final start = _currentWeekStart;
    return start.add(const Duration(days: 6, hours: 23, minutes: 59));
  }

  WeeklyReview getOrCreateCurrentWeeklyReview() {
    if (_currentWeeklyReview != null &&
        _currentWeeklyReview!.weekStart == _currentWeekStart) {
      return _currentWeeklyReview!;
    }

    // Filter sessions once for both totalSessions and totalPointsEarned
    final weekEnd = _currentWeekEnd.add(const Duration(days: 1));
    final weekSessions = _focusProvider.sessions
        .where((s) =>
            s.startTime.isAfter(_currentWeekStart) &&
            s.startTime.isBefore(weekEnd) &&
            s.completed)
        .toList();

    _currentWeeklyReview = WeeklyReview(
      id: 'review_${_currentWeekStart.millisecondsSinceEpoch}',
      weekStart: _currentWeekStart,
      weekEnd: _currentWeekEnd,
      reflections: [],
      goals: WeeklyReview.getDefaultGoals(_personaProvider.ageGroup),
      totalFocusMinutes:
          _focusProvider.weeklyFocusMinutes.fold(0, (a, b) => a + b),
      totalSessions: weekSessions.length,
      totalPointsEarned:
          weekSessions.fold(0, (a, b) => a + b.pointsEarned),
      streakDays: _focusProvider.computedStreakDays,
      createdAt: DateTime.now(),
    );
    notifyListeners();
    return _currentWeeklyReview!;
  }

  void setWeeklyMood(WeeklyMood mood) {
    final review = getOrCreateCurrentWeeklyReview();
    _currentWeeklyReview = WeeklyReview(
      id: review.id,
      weekStart: review.weekStart,
      weekEnd: review.weekEnd,
      mood: mood,
      reflections: review.reflections,
      goals: review.goals,
      totalFocusMinutes: review.totalFocusMinutes,
      totalSessions: review.totalSessions,
      totalPointsEarned: review.totalPointsEarned,
      streakDays: review.streakDays,
      aiInsight: review.aiInsight,
      createdAt: review.createdAt,
    );
    notifyListeners();
  }

  void addWeeklyReflection(String question, String answer) {
    final review = getOrCreateCurrentWeeklyReview();
    final reflection = WeeklyReflection(
      id: 'ref_${DateTime.now().millisecondsSinceEpoch}',
      question: question,
      answer: answer,
      createdAt: DateTime.now(),
    );
    _currentWeeklyReview = WeeklyReview(
      id: review.id,
      weekStart: review.weekStart,
      weekEnd: review.weekEnd,
      mood: review.mood,
      reflections: [...review.reflections, reflection],
      goals: review.goals,
      totalFocusMinutes: review.totalFocusMinutes,
      totalSessions: review.totalSessions,
      totalPointsEarned: review.totalPointsEarned,
      streakDays: review.streakDays,
      aiInsight: review.aiInsight,
      createdAt: review.createdAt,
    );
    notifyListeners();
  }

  void updateWeeklyGoalProgress(String goalId, int completedMinutes) {
    final review = getOrCreateCurrentWeeklyReview();
    final updatedGoals = review.goals.map((goal) {
      if (goal.id == goalId) {
        return goal.copyWith(
          completedMinutes: completedMinutes,
          isCompleted: completedMinutes >= goal.targetMinutes,
        );
      }
      return goal;
    }).toList();

    _currentWeeklyReview = WeeklyReview(
      id: review.id,
      weekStart: review.weekStart,
      weekEnd: review.weekEnd,
      mood: review.mood,
      reflections: review.reflections,
      goals: updatedGoals,
      totalFocusMinutes: review.totalFocusMinutes,
      totalSessions: review.totalSessions,
      totalPointsEarned: review.totalPointsEarned,
      streakDays: review.streakDays,
      aiInsight: review.aiInsight,
      createdAt: review.createdAt,
    );
    notifyListeners();
  }

  void addWeeklyGoal(String title, int targetMinutes) {
    final review = getOrCreateCurrentWeeklyReview();
    final newGoal = WeeklyGoal(
      id: 'goal_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      targetMinutes: targetMinutes,
      createdAt: _currentWeekStart,
    );
    _currentWeeklyReview = WeeklyReview(
      id: review.id,
      weekStart: review.weekStart,
      weekEnd: review.weekEnd,
      mood: review.mood,
      reflections: review.reflections,
      goals: [...review.goals, newGoal],
      totalFocusMinutes: review.totalFocusMinutes,
      totalSessions: review.totalSessions,
      totalPointsEarned: review.totalPointsEarned,
      streakDays: review.streakDays,
      aiInsight: review.aiInsight,
      createdAt: review.createdAt,
    );
    notifyListeners();
  }

  void removeWeeklyGoal(String goalId) {
    final review = getOrCreateCurrentWeeklyReview();
    _currentWeeklyReview = WeeklyReview(
      id: review.id,
      weekStart: review.weekStart,
      weekEnd: review.weekEnd,
      mood: review.mood,
      reflections: review.reflections,
      goals: review.goals.where((g) => g.id != goalId).toList(),
      totalFocusMinutes: review.totalFocusMinutes,
      totalSessions: review.totalSessions,
      totalPointsEarned: review.totalPointsEarned,
      streakDays: review.streakDays,
      aiInsight: review.aiInsight,
      createdAt: review.createdAt,
    );
    notifyListeners();
  }

  void setWeeklyAiInsight(String insight) {
    final review = getOrCreateCurrentWeeklyReview();
    _currentWeeklyReview = WeeklyReview(
      id: review.id,
      weekStart: review.weekStart,
      weekEnd: review.weekEnd,
      mood: review.mood,
      reflections: review.reflections,
      goals: review.goals,
      totalFocusMinutes: review.totalFocusMinutes,
      totalSessions: review.totalSessions,
      totalPointsEarned: review.totalPointsEarned,
      streakDays: review.streakDays,
      aiInsight: insight,
      createdAt: review.createdAt,
    );
    notifyListeners();
  }

  void saveWeeklyReview() {
    if (_currentWeeklyReview != null) {
      _weeklyReviewHistory.add(_currentWeeklyReview!);
      _currentWeeklyReview = null;
      notifyListeners();
    }
  }

  WeeklyReview? getWeeklyReviewForWeek(DateTime weekStart) {
    try {
      return _weeklyReviewHistory.firstWhere(
        (r) => r.weekStart == weekStart,
      );
    } catch (_) {
      return null;
    }
  }

  void clearAll() {
    _currentWeeklyReview = null;
    _weeklyReviewHistory = [];
    notifyListeners();
  }
}
