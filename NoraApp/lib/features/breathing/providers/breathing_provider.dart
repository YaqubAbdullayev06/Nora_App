import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/breathing_pattern.dart';

/// Manages breathing exercise state: session lifecycle, phase timing, stats.
class BreathingProvider extends ChangeNotifier {
  // ─── Session State ───
  BreathingPattern? _selectedPattern;
  bool _isSessionActive = false;
  bool _isPaused = false;
  int _currentPhaseIndex = 0;
  int _phaseCountdown = 0;
  int _sessionElapsedSeconds = 0;
  int _sessionDurationMinutes = 3;
  int _sessionPointsEarned = 0;
  Timer? _phaseTimer;

  // ─── Stats ───
  BreathingStats _stats = const BreathingStats();

  // ─── Getters ───
  BreathingPattern? get selectedPattern => _selectedPattern;
  bool get isSessionActive => _isSessionActive;
  bool get isPaused => _isPaused;
  int get currentPhaseIndex => _currentPhaseIndex;
  int get phaseCountdown => _phaseCountdown;
  int get sessionElapsedSeconds => _sessionElapsedSeconds;
  int get sessionDurationMinutes => _sessionDurationMinutes;
  int get sessionPointsEarned => _sessionPointsEarned;
  BreathingStats get stats => _stats;

  /// Current phase, or null if no session.
  BreathingPhase? get currentPhase {
    if (_selectedPattern == null) return null;
    if (_currentPhaseIndex >= _selectedPattern!.phases.length) return null;
    return _selectedPattern!.phases[_currentPhaseIndex];
  }

  /// Progress through the current phase (0.0 to 1.0).
  double get phaseProgress {
    if (currentPhase == null || currentPhase!.durationSeconds == 0) return 0;
    return 1.0 - (_phaseCountdown / currentPhase!.durationSeconds);
  }

  /// Overall session progress (0.0 to 1.0).
  double get sessionProgress {
    final totalSeconds = _sessionDurationMinutes * 60;
    if (totalSeconds == 0) return 0;
    return (_sessionElapsedSeconds / totalSeconds).clamp(0.0, 1.0);
  }

  /// Formatted elapsed time "MM:SS".
  String get elapsedDisplay {
    final m = _sessionElapsedSeconds ~/ 60;
    final s = _sessionElapsedSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  // ─── Session Actions ───

  /// Start a breathing session with the given pattern and duration.
  void startSession(BreathingPattern pattern, int durationMinutes) {
    _selectedPattern = pattern;
    _sessionDurationMinutes = durationMinutes;
    _currentPhaseIndex = 0;
    _sessionElapsedSeconds = 0;
    _sessionPointsEarned = 0;
    _isSessionActive = true;
    _isPaused = false;
    _phaseCountdown = pattern.phases.first.durationSeconds;
    _startPhaseTimer();
    notifyListeners();
  }

  /// Pause the current session.
  void pauseSession() {
    if (!_isSessionActive || _isPaused) return;
    _isPaused = true;
    _phaseTimer?.cancel();
    notifyListeners();
  }

  /// Resume a paused session.
  void resumeSession() {
    if (!_isSessionActive || !_isPaused) return;
    _isPaused = false;
    _startPhaseTimer();
    notifyListeners();
  }

  /// Stop the session early (partial completion).
  void stopSession() {
    _phaseTimer?.cancel();
    if (_sessionElapsedSeconds >= 30) {
      _completeSession();
    } else {
      _resetSession();
    }
    notifyListeners();
  }

  // ─── Internal ───

  void _startPhaseTimer() {
    _phaseTimer?.cancel();
    _phaseTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _tick();
    });
  }

  void _tick() {
    if (_isPaused || !_isSessionActive) return;

    // Advance phase countdown
    if (_phaseCountdown > 1) {
      _phaseCountdown--;
    } else {
      // Phase complete — advance to next
      _advancePhase();
    }

    // Advance session timer
    _sessionElapsedSeconds++;

    // Check if session duration reached
    if (_sessionElapsedSeconds >= _sessionDurationMinutes * 60) {
      _completeSession();
      return;
    }

    notifyListeners();
  }

  void _advancePhase() {
    if (_selectedPattern == null) return;
    _currentPhaseIndex++;
    if (_currentPhaseIndex >= _selectedPattern!.phases.length) {
      _currentPhaseIndex = 0; // Loop back to start of cycle
    }
    _phaseCountdown = _selectedPattern!.phases[_currentPhaseIndex].durationSeconds;
  }

  void _completeSession() {
    _phaseTimer?.cancel();
    final minutes = _sessionElapsedSeconds ~/ 60;
    final points = (minutes * 5).toInt();
    _sessionPointsEarned = points;

    // Update stats
    final now = DateTime.now();
    final newTotalSessions = _stats.totalSessions + 1;
    final newTotalMinutes = _stats.totalMinutes + minutes;
    final newPoints = _stats.pointsEarned + points;

    // Compute streak
    int newStreak = _stats.currentStreak;
    if (_stats.lastSessionDate != null) {
      final lastDate = DateTime(
        _stats.lastSessionDate!.year,
        _stats.lastSessionDate!.month,
        _stats.lastSessionDate!.day,
      );
      final today = DateTime(now.year, now.month, now.day);
      final diff = today.difference(lastDate).inDays;
      if (diff == 0) {
        // Same day — streak unchanged
      } else if (diff == 1) {
        newStreak++;
      } else {
        newStreak = 1;
      }
    } else {
      newStreak = 1;
    }

    _stats = BreathingStats(
      totalSessions: newTotalSessions,
      totalMinutes: newTotalMinutes,
      currentStreak: newStreak,
      pointsEarned: newPoints,
      lastSessionDate: now,
    );

    _isSessionActive = false;
    _isPaused = false;
    notifyListeners();
  }

  void _resetSession() {
    _phaseTimer?.cancel();
    _isSessionActive = false;
    _isPaused = false;
    _currentPhaseIndex = 0;
    _phaseCountdown = 0;
    _sessionElapsedSeconds = 0;
    _sessionPointsEarned = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _phaseTimer?.cancel();
    super.dispose();
  }
}
