import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists setup wizard state and user choices.
class SetupProvider extends ChangeNotifier {
  static const _keyCompleted = 'setup_wizard_completed';
  static const _keyAccountability = 'setup_accountability_lock';
  static const _keyHardCap = 'setup_daily_hard_cap';
  static const _keyHardCapMinutes = 'setup_hard_cap_minutes';
  static const _keyPomodoro = 'setup_pomodoro_cycles';
  static const _keyPomodoroCycles = 'setup_pomodoro_target_cycles';
  static const _keyEarnScreenTime = 'setup_earn_screen_time';
  static const _keyPermissions = 'setup_permissions_granted';

  final _storage = const FlutterSecureStorage();

  bool _isCompleted = false;
  bool _accountabilityEnabled = false;
  bool _hardCapEnabled = false;
  int _hardCapMinutes = 120; // default 2h
  bool _pomodoroEnabled = false;
  int _pomodoroCycles = 3;
  bool _earnScreenTimeEnabled = false;
  bool _permissionsGranted = false;

  bool get isCompleted => _isCompleted;
  bool get accountabilityEnabled => _accountabilityEnabled;
  bool get hardCapEnabled => _hardCapEnabled;
  int get hardCapMinutes => _hardCapMinutes;
  bool get pomodoroEnabled => _pomodoroEnabled;
  int get pomodoroCycles => _pomodoroCycles;
  bool get earnScreenTimeEnabled => _earnScreenTimeEnabled;
  bool get permissionsGranted => _permissionsGranted;

  /// Load saved state from secure storage.
  Future<void> load() async {
    _isCompleted = (await _storage.read(key: _keyCompleted)) == 'true';
    _accountabilityEnabled = (await _storage.read(key: _keyAccountability)) == 'true';
    _hardCapEnabled = (await _storage.read(key: _keyHardCap)) == 'true';
    _hardCapMinutes = int.tryParse(await _storage.read(key: _keyHardCapMinutes) ?? '') ?? 120;
    _pomodoroEnabled = (await _storage.read(key: _keyPomodoro)) == 'true';
    _pomodoroCycles = int.tryParse(await _storage.read(key: _keyPomodoroCycles) ?? '') ?? 3;
    _earnScreenTimeEnabled = (await _storage.read(key: _keyEarnScreenTime)) == 'true';
    _permissionsGranted = (await _storage.read(key: _keyPermissions)) == 'true';
    notifyListeners();
  }

  void setAccountability(bool value) {
    _accountabilityEnabled = value;
    notifyListeners();
  }

  void setHardCap(bool value, {int? minutes}) {
    _hardCapEnabled = value;
    if (minutes != null) _hardCapMinutes = minutes;
    notifyListeners();
  }

  void setHardCapMinutes(int minutes) {
    _hardCapMinutes = minutes;
    notifyListeners();
  }

  void setPomodoro(bool value, {int? cycles}) {
    _pomodoroEnabled = value;
    if (cycles != null) _pomodoroCycles = cycles;
    notifyListeners();
  }

  void setPomodoroCycles(int cycles) {
    _pomodoroCycles = cycles;
    notifyListeners();
  }

  void setEarnScreenTime(bool value) {
    _earnScreenTimeEnabled = value;
    notifyListeners();
  }

  void setPermissionsGranted(bool value) {
    _permissionsGranted = value;
    notifyListeners();
  }

  /// Save all choices and mark wizard as completed.
  Future<void> complete() async {
    await Future.wait([
      _storage.write(key: _keyCompleted, value: 'true'),
      _storage.write(key: _keyAccountability, value: _accountabilityEnabled.toString()),
      _storage.write(key: _keyHardCap, value: _hardCapEnabled.toString()),
      _storage.write(key: _keyHardCapMinutes, value: _hardCapMinutes.toString()),
      _storage.write(key: _keyPomodoro, value: _pomodoroEnabled.toString()),
      _storage.write(key: _keyPomodoroCycles, value: _pomodoroCycles.toString()),
      _storage.write(key: _keyEarnScreenTime, value: _earnScreenTimeEnabled.toString()),
      _storage.write(key: _keyPermissions, value: _permissionsGranted.toString()),
    ]);
    _isCompleted = true;
    notifyListeners();
  }

  /// Reset wizard (for re-entry from settings).
  Future<void> reset() async {
    await _storage.write(key: _keyCompleted, value: 'false');
    _isCompleted = false;
    notifyListeners();
  }
}
