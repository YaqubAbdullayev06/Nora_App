import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// PomodoroProvider — Manages automatic multi-cycle Pomodoro configuration.
///
/// Tracks:
/// - Whether auto-cycle is enabled
/// - Number of cycles to complete
/// - Completed cycles today
/// - Total focus sessions today
/// - Custom work/break durations (optional, defaults to age-group settings)
class PomodoroProvider extends ChangeNotifier {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  bool _isInitialized = false;
  Timer? _dayCheckTimer;
  /// M35: mutation epoch so a stale async `_loadLocal` can't clobber
  /// toggles the user made while the load was in flight.
  int _mutationEpoch = 0;

  // ─── State ───
  bool _autoCycleEnabled = false;
  int _targetCycles = 1; // How many full cycles to complete
  int _completedCycles = 0; // Cycles completed today
  int _totalSessionsToday = 0; // Total focus sessions today
  int _totalFocusMinutesToday = 0; // Total focus minutes today

  // ─── Storage Keys ───
  static const _autoCycleKey = 'pomodoro_auto_cycle';
  static const _targetCyclesKey = 'pomodoro_target_cycles';
  static const _completedCyclesKey = 'pomodoro_completed_cycles';
  static const _totalSessionsKey = 'pomodoro_total_sessions';
  static const _totalFocusKey = 'pomodoro_total_focus';
  static const _lastDateKey = 'pomodoro_last_date';

  // ─── Getters ───
  bool get autoCycleEnabled {
    if (!_isInitialized) Future.microtask(initialize); // defer side effects out of build
    return _autoCycleEnabled;
  }

  int get targetCycles => _targetCycles;
  int get completedCycles => _completedCycles;
  int get totalSessionsToday => _totalSessionsToday;
  int get totalFocusMinutesToday => _totalFocusMinutesToday;

  /// Whether all target cycles are completed.
  bool get allCyclesCompleted => _completedCycles >= _targetCycles;

  /// Progress through target cycles (0.0 to 1.0+).
  double get cycleProgress {
    if (_targetCycles <= 0) return 0.0;
    return _completedCycles / _targetCycles;
  }

  /// Initialize — loads settings from local storage.
  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;
    await _loadLocal();
    await _checkDailyReset();
    _startDayWatch();
    notifyListeners();
  }

  /// M15: rollover check while the app stays open past midnight —
  /// `_checkDailyReset` previously ran only once, during initialize().
  void _startDayWatch() {
    _dayCheckTimer?.cancel();
    _dayCheckTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _checkDailyReset(),
    );
  }

  // ─── Configuration ───

  /// Toggle auto-cycle on/off.
  Future<void> toggleAutoCycle() async {
    _mutationEpoch++; // M35
    _autoCycleEnabled = !_autoCycleEnabled;
    await _saveLocal();
    notifyListeners();
  }

  /// Set the target number of cycles.
  Future<void> setTargetCycles(int cycles) async {
    _mutationEpoch++; // M35
    _targetCycles = cycles.clamp(1, 10);
    await _saveLocal();
    notifyListeners();
  }

  // ─── Cycle Tracking ───

  /// Record a completed focus session.
  void recordSession(int minutes) {
    _mutationEpoch++; // M35
    _totalSessionsToday++;
    _totalFocusMinutesToday += minutes;
    _saveLocal();
    notifyListeners();
  }

  /// Record a completed cycle (after long break).
  void recordCycleCompleted() {
    _mutationEpoch++; // M35
    _completedCycles++;
    _saveLocal();
    notifyListeners();
  }

  /// Reset all daily stats (new day or manual reset).
  void resetDailyStats() {
    _mutationEpoch++; // M35
    _completedCycles = 0;
    _totalSessionsToday = 0;
    _totalFocusMinutesToday = 0;
    _saveLocal();
    notifyListeners();
  }

  // ─── Private Methods ───

  Future<void> _checkDailyReset() async {
    _mutationEpoch++; // M35
    final savedDate = await _storage.read(key: _lastDateKey);
    final today = DateTime.now().toIso8601String().substring(0, 10);

    if (savedDate != today) {
      // New day — reset daily stats
      _completedCycles = 0;
      _totalSessionsToday = 0;
      _totalFocusMinutesToday = 0;
      await _storage.write(key: _lastDateKey, value: today);
      await _saveLocal();
      notifyListeners();
    }
  }

  // ─── Local Storage ───

  Future<void> _loadLocal() async {
    // M35: collect reads first; assign only if no mutation happened meanwhile
    final epoch = _mutationEpoch;
    try {
      final autoCycle = await _storage.read(key: _autoCycleKey);
      final targetStr = await _storage.read(key: _targetCyclesKey);
      final completedStr = await _storage.read(key: _completedCyclesKey);
      final sessionsStr = await _storage.read(key: _totalSessionsKey);
      final focusStr = await _storage.read(key: _totalFocusKey);

      if (epoch != _mutationEpoch) return; // stale — discard

      _autoCycleEnabled = autoCycle == 'true';
      if (targetStr != null) _targetCycles = int.tryParse(targetStr) ?? 1;
      if (completedStr != null) {
        _completedCycles = int.tryParse(completedStr) ?? 0;
      }
      if (sessionsStr != null) {
        _totalSessionsToday = int.tryParse(sessionsStr) ?? 0;
      }
      if (focusStr != null) {
        _totalFocusMinutesToday = int.tryParse(focusStr) ?? 0;
      }
    } catch (e) {
      debugPrint('PomodoroProvider: failed to load local: $e');
    }
  }

  Future<void> _saveLocal() async {
    try {
      await _storage.write(
          key: _autoCycleKey, value: _autoCycleEnabled.toString());
      await _storage.write(
          key: _targetCyclesKey, value: _targetCycles.toString());
      await _storage.write(
          key: _completedCyclesKey, value: _completedCycles.toString());
      await _storage.write(
          key: _totalSessionsKey, value: _totalSessionsToday.toString());
      await _storage.write(
          key: _totalFocusKey, value: _totalFocusMinutesToday.toString());
    } catch (e) {
      debugPrint('PomodoroProvider: failed to save: $e');
    }
  }

  @override
  void dispose() {
    _dayCheckTimer?.cancel();
    super.dispose();
  }
}
