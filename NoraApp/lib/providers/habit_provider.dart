import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/models.dart';
import '../services/api_service.dart';

/// HabitProvider — Manages real-world habits and their screen-time rewards.
///
/// Tracks:
/// - User's defined habits
/// - Daily completions
/// - Screen time earned from habits
class HabitProvider extends ChangeNotifier {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final ApiService _api = ApiService();
  bool _isInitialized = false;

  // ─── State ───
  List<Habit> _habits = [];
  int _todayCompletions = 0;
  int _todayScreenTimeEarned = 0;
  int _weekScreenTimeEarned = 0;
  bool _isLoading = false;
  String? _error;

  // ─── Storage Keys ───
  static const _todayCompletionsKey = 'habits_today_completions';
  static const _todayEarnedKey = 'habits_today_earned';
  static const _weekEarnedKey = 'habits_week_earned';
  static const _lastDateKey = 'habits_last_date';

  // ─── Getters ───
  List<Habit> get habits {
    if (!_isInitialized) Future.microtask(initialize); // defer side effects out of build
    return _habits;
  }

  int get todayCompletions => _todayCompletions;
  int get todayScreenTimeEarned => _todayScreenTimeEarned;
  int get weekScreenTimeEarned => _weekScreenTimeEarned;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// All habits completed today.
  List<Habit> get completedHabits =>
      _habits.where((h) => h.isCompletedToday).toList();

  /// Habits not yet completed today.
  List<Habit> get pendingHabits =>
      _habits.where((h) => !h.isCompletedToday).toList();

  /// Initialize — loads habits from local storage.
  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;
    await _loadLocal();
    await _checkDailyReset();
    notifyListeners();
  }

  // ─── CRUD ───

  /// Create a new habit.
  Future<bool> createHabit({
    required String name,
    String category = 'general',
    String icon = 'check_circle',
    String color = '#4CAF50',
    int screenTimeMinutes = 15,
    int targetPerDay = 1,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.createHabit(
        name: name,
        category: category,
        icon: icon,
        color: color,
        screenTimeMinutes: screenTimeMinutes,
        targetPerDay: targetPerDay,
      );

      if (response['success'] == true) {
        // refreshHabits() calls _saveLocal + notifyListeners — no extra call needed
        await refreshHabits();
        _isLoading = false;
        return true;
      }

      _error = response['detail'] ?? 'Failed to create habit';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Failed to connect to server';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Complete a habit and earn screen time.
  Future<int?> completeHabit(int habitId, {int durationMinutes = 0}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.completeHabit(
        habitId: habitId,
        durationMinutes: durationMinutes,
      );

      if (response['success'] == true) {
        final screenTimeEarned = (response['screen_time_earned'] ?? 0) as int;
        _todayScreenTimeEarned += screenTimeEarned;
        _weekScreenTimeEarned += screenTimeEarned;
        _todayCompletions = (response['completions_today'] ?? _todayCompletions) as int;
        await _saveLocal();
        // refreshHabits() calls _saveLocal + notifyListeners — no extra call needed
        await refreshHabits();
        _isLoading = false;
        return screenTimeEarned;
      }

      _error = response['detail'] ?? 'Failed to complete habit';
      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _error = 'Failed to connect to server';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Delete (deactivate) a habit.
  Future<bool> deleteHabit(int habitId) async {
    try {
      final response = await _api.deleteHabit(habitId);
      if (response['success'] == true) {
        _habits = _habits.where((h) => h.id != habitId).toList();
        await _saveLocal();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Refresh habits from backend.
  Future<void> refreshHabits() async {
    try {
      final response = await _api.listHabits();
      if (response['success'] == true) {
        final habitsList = response['habits'] as List? ?? [];
        _habits = habitsList.map((h) => Habit.fromJson(h)).toList();
        await _saveLocal();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('HabitProvider: refresh failed: $e');
    }
  }

  /// Refresh stats from backend.
  Future<void> refreshStats() async {
    try {
      final response = await _api.getHabitStats();
      if (response['success'] == true) {
        _todayCompletions = response['today_completions'] ?? 0;
        _todayScreenTimeEarned = response['today_screen_time_earned'] ?? 0;
        _weekScreenTimeEarned = response['week_screen_time_earned'] ?? 0;
        await _saveLocal();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('HabitProvider: stats refresh failed: $e');
    }
  }

  // ─── Private Methods ───

  Future<void> _checkDailyReset() async {
    final savedDate = await _storage.read(key: _lastDateKey);
    final today = DateTime.now().toIso8601String().substring(0, 10);

    if (savedDate != today) {
      // New day — reset daily stats
      _todayCompletions = 0;
      _todayScreenTimeEarned = 0;
      await _storage.write(key: _lastDateKey, value: today);
      await _saveLocal();
      notifyListeners();
    }
  }

  // ─── Local Storage ───

  Future<void> _loadLocal() async {
    try {
      final todayStr = await _storage.read(key: _todayCompletionsKey);
      if (todayStr != null) _todayCompletions = int.tryParse(todayStr) ?? 0;

      final earnedStr = await _storage.read(key: _todayEarnedKey);
      if (earnedStr != null) {
        _todayScreenTimeEarned = int.tryParse(earnedStr) ?? 0;
      }

      final weekStr = await _storage.read(key: _weekEarnedKey);
      if (weekStr != null) _weekScreenTimeEarned = int.tryParse(weekStr) ?? 0;
    } catch (e) {
      debugPrint('HabitProvider: failed to load local: $e');
    }
  }

  Future<void> _saveLocal() async {
    try {
      await Future.wait([
        _storage.write(
            key: _todayCompletionsKey, value: _todayCompletions.toString()),
        _storage.write(
            key: _todayEarnedKey, value: _todayScreenTimeEarned.toString()),
        _storage.write(
            key: _weekEarnedKey, value: _weekScreenTimeEarned.toString()),
      ]);
    } catch (e) {
      debugPrint('HabitProvider: failed to save: $e');
    }
  }
}
