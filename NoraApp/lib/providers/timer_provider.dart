import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../core/enums/age_group.dart';
import '../models/models.dart';
import '../services/focus_protection_service.dart';
import 'persona_provider.dart';

/// Manages timer state, break phases, and pomodoro cycles.
class TimerProvider extends ChangeNotifier {
  final FocusProtectionService _focusProtection = FocusProtectionService();
  final PersonaProvider _personaProvider;

  Timer? _timer;

  bool _isTimerRunning = false;
  int _timerSeconds = 0;
  int _totalTimerSeconds = 0;
  bool _isBreakPhase = false;
  int _completedSessionsInCycle = 0;

  TimerProvider({required PersonaProvider personaProvider})
      : _personaProvider = personaProvider {
    _totalTimerSeconds = _personaProvider.ageGroup.defaultFocusMinutes * 60;
    _timerSeconds = _totalTimerSeconds;
  }

  bool get isTimerRunning => _isTimerRunning;
  int get timerSeconds => _timerSeconds;
  int get totalTimerSeconds => _totalTimerSeconds;
  bool get isBreakPhase => _isBreakPhase;
  int get completedSessionsInCycle => _completedSessionsInCycle;

  bool get isLongBreak =>
      _completedSessionsInCycle > 0 &&
      _completedSessionsInCycle %
              _personaProvider.ageGroup.pomodoroSessionsPerCycle ==
          0;

  int get breakDurationSeconds =>
      (isLongBreak
              ? _personaProvider.ageGroup.longBreakMinutes
              : _personaProvider.ageGroup.breakMinutes) *
          60;

  String get timerDisplay {
    final minutes = _timerSeconds ~/ 60;
    final secs = _timerSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  double get timerProgress =>
      _totalTimerSeconds > 0 ? _timerSeconds / _totalTimerSeconds : 0;

  /// Called by FocusProvider when a session completes.
  void Function(FocusSession session)? onSessionCompleted;

  void setTimerDuration(int minutes) {
    _totalTimerSeconds = minutes * 60;
    _timerSeconds = _totalTimerSeconds;
    if (_isBreakPhase) {
      _isBreakPhase = false;
      _completedSessionsInCycle = 0;
    }
    notifyListeners();
  }

  void startTimer() {
    if (_isTimerRunning) return;
    unawaited(_focusProtection.enableBlocking());
    _isTimerRunning = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timerSeconds > 0) {
        _timerSeconds--;
        notifyListeners();
      } else {
        _timerComplete();
      }
    });
    notifyListeners();
  }

  void pauseTimer() {
    _isTimerRunning = false;
    _timer?.cancel();
    unawaited(_focusProtection.disableBlocking());
    notifyListeners();
  }

  void resetTimer() {
    _isTimerRunning = false;
    _timer?.cancel();
    _timerSeconds = _totalTimerSeconds;
    unawaited(_focusProtection.disableBlocking());
    notifyListeners();
  }

  void _timerComplete() {
    _timer?.cancel();
    _isTimerRunning = false;
    unawaited(_focusProtection.disableBlocking());
    final minutes = _totalTimerSeconds ~/ 60;
    final points =
        (minutes * 10 * _personaProvider.ageGroup.pointsMultiplier).toInt();

    // Record the session
    final now = DateTime.now();
    final session = FocusSession(
      id: 'session_${now.millisecondsSinceEpoch}',
      startTime: now.subtract(Duration(seconds: _totalTimerSeconds)),
      endTime: now,
      durationMinutes: minutes,
      pointsEarned: points,
      completed: true,
    );

    onSessionCompleted?.call(session);

    _vibrate();

    // Transition to break phase
    _isBreakPhase = true;
    _timerSeconds = breakDurationSeconds;
    _totalTimerSeconds = breakDurationSeconds;

    notifyListeners();
  }

  void completeBreak() {
    _timer?.cancel();
    _isTimerRunning = false;
    _isBreakPhase = false;

    if (isLongBreak) {
      _completedSessionsInCycle = 0;
    }

    _timerSeconds = _personaProvider.ageGroup.defaultFocusMinutes * 60;
    _totalTimerSeconds = _timerSeconds;

    _vibrate();
    notifyListeners();
  }

  void skipBreak() {
    completeBreak();
  }

  void startBreakTimer() {
    if (_isTimerRunning || !_isBreakPhase) return;
    _isTimerRunning = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timerSeconds > 0) {
        _timerSeconds--;
        notifyListeners();
      } else {
        completeBreak();
      }
    });
    notifyListeners();
  }

  void completeTimer() {
    _timerComplete();
  }

  void _vibrate() {
    try {
      HapticFeedback.mediumImpact();
    } catch (_) {
      // Haptic feedback may not be available on all platforms
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
