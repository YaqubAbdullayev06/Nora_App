import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_service.dart';

/// Friction level based on usage progress.
enum FrictionLevel {
  none,       // < soft_warning_percent
  soft,       // >= soft_warning_percent, < hard_warning_percent
  hard,       // >= hard_warning_percent, < 100%
  blocked,    // >= 100%
}

/// HardCapProvider — Manages daily total screen time hard cap with progressive friction.
///
/// Shows warnings at configurable thresholds:
/// - Soft warning: notification/badge
/// - Hard warning: modal with reflection
/// - Blocked: full-screen overlay (PIN override if accountability is set)
class HardCapProvider extends ChangeNotifier {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final ApiService _api = ApiService();
  bool _isInitialized = false;

  // ─── State ───
  bool _isActive = false;
  int _capMinutes = 120; // Default 2 hours
  int _softWarningPercent = 80;
  int _hardWarningPercent = 90;
  bool _requirePinToOverride = false;
  int _todayUsageMinutes = 0;
  int _bonusMinutesToday = 0; // Screen time earned from habits
  bool _setupInProgress = false;
  String? _error;

  // Tracking for friction display
  bool _softWarningShown = false;
  bool _hardWarningShown = false;
  bool _blockedShown = false;

  // ─── Storage Keys ───
  static const _capMinutesKey = 'hardcap_minutes';
  static const _softWarningKey = 'hardcap_soft_warning';
  static const _hardWarningKey = 'hardcap_hard_warning';
  static const _requirePinKey = 'hardcap_require_pin';
  static const _isActiveKey = 'hardcap_is_active';
  static const _todayUsageKey = 'hardcap_today_usage';
  static const _bonusMinutesKey = 'hardcap_bonus_minutes';
  static const _usageDateKey = 'hardcap_usage_date';
  static const _softShownKey = 'hardcap_soft_shown';
  static const _hardShownKey = 'hardcap_hard_shown';
  static const _blockedShownKey = 'hardcap_blocked_shown';

  // ─── Getters ───
  bool get isActive {
    if (!_isInitialized) initialize(); // fire-and-forget
    return _isActive;
  }
  int get capMinutes => _capMinutes;
  int get softWarningPercent => _softWarningPercent;
  int get hardWarningPercent => _hardWarningPercent;
  bool get requirePinToOverride => _requirePinToOverride;
  int get todayUsageMinutes => _todayUsageMinutes;
  int get bonusMinutesToday => _bonusMinutesToday;
  bool get setupInProgress => _setupInProgress;
  String? get error => _error;
  bool get softWarningShown => _softWarningShown;
  bool get hardWarningShown => _hardWarningShown;
  bool get blockedShown => _blockedShown;

  /// Get usage progress as 0.0 - 1.0+.
  double get usageProgress {
    if (_capMinutes <= 0) return 0.0;
    return _todayUsageMinutes / (_capMinutes + _bonusMinutesToday);
  }

  /// Get remaining minutes (can be negative if over cap).
  /// Bonus minutes from habits extend the effective cap.
  int get remainingMinutes =>
      (_capMinutes + _bonusMinutesToday) - _todayUsageMinutes;

  /// Get current friction level.
  FrictionLevel get frictionLevel {
    if (!_isActive) return FrictionLevel.none;

    final percent = (usageProgress * 100).round();
    if (percent >= 100) return FrictionLevel.blocked;
    if (percent >= _hardWarningPercent) return FrictionLevel.hard;
    if (percent >= _softWarningPercent) return FrictionLevel.soft;
    return FrictionLevel.none;
  }

  /// Initialize — loads cap settings from local storage.
  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;
    await _loadLocalCap();
    await _checkDailyReset();
    notifyListeners();
  }

  // ─── Setup ───

  /// Set up or update the hard cap.
  Future<bool> setupCap({
    required int capMinutes,
    int softWarningPercent = 80,
    int hardWarningPercent = 90,
    bool requirePinToOverride = false,
  }) async {
    _setupInProgress = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.setupHardCap(
        capMinutes: capMinutes,
        softWarningPercent: softWarningPercent,
        hardWarningPercent: hardWarningPercent,
        requirePinToOverride: requirePinToOverride,
      );

      if (response['success'] == true) {
        _isActive = true;
        _capMinutes = capMinutes;
        _softWarningPercent = softWarningPercent;
        _hardWarningPercent = hardWarningPercent;
        _requirePinToOverride = requirePinToOverride;
        _softWarningShown = false;
        _hardWarningShown = false;
        _blockedShown = false;
        await _saveLocalCap();
        _setupInProgress = false;
        notifyListeners();
        return true;
      }

      _error = response['detail'] ?? 'Failed to set up hard cap';
      _setupInProgress = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Failed to connect to server';
      _setupInProgress = false;
      notifyListeners();
      return false;
    }
  }

  /// Deactivate the hard cap.
  Future<bool> deactivateCap() async {
    try {
      final response = await _api.deactivateHardCap();
      if (response['success'] == true) {
        _isActive = false;
        await _clearLocalCap();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // ─── Usage Tracking ───

  /// Record additional screen time usage (in minutes).
  void recordUsage(int minutes) {
    _todayUsageMinutes += minutes;
    _saveLocalUsage();
    _checkFriction();
    notifyListeners();
  }

  /// Set total usage for today (from screen time API).
  void setTodayUsage(int minutes) {
    _todayUsageMinutes = minutes;
    _saveLocalUsage();
    _checkFriction();
    notifyListeners();
  }

  /// Add bonus minutes earned from completing real-world habits.
  void addBonusMinutes(int minutes) {
    _bonusMinutesToday += minutes;
    _saveLocalUsage();
    _checkFriction();
    notifyListeners();
  }

  /// Mark a friction warning as shown.
  void markSoftWarningShown() {
    _softWarningShown = true;
    _saveLocalUsage();
    notifyListeners();
  }

  void markHardWarningShown() {
    _hardWarningShown = true;
    _saveLocalUsage();
    notifyListeners();
  }

  void markBlockedShown() {
    _blockedShown = true;
    _saveLocalUsage();
    notifyListeners();
  }

  /// Reset friction warnings (e.g., after PIN override or new day).
  void resetFrictionWarnings() {
    _softWarningShown = false;
    _hardWarningShown = false;
    _blockedShown = false;
    _saveLocalUsage();
    notifyListeners();
  }

  // ─── Private Methods ───

  void _checkFriction() {
    final level = frictionLevel;

    // Reset shown flags if we've dropped back below threshold
    if (level == FrictionLevel.none) {
      _softWarningShown = false;
      _hardWarningShown = false;
      _blockedShown = false;
    } else if (level == FrictionLevel.soft) {
      _hardWarningShown = false;
      _blockedShown = false;
    } else if (level == FrictionLevel.hard) {
      _blockedShown = false;
    }
  }

  Future<void> _checkDailyReset() async {
    final savedDate = await _storage.read(key: _usageDateKey);
    final today = DateTime.now().toIso8601String().substring(0, 10);

    if (savedDate != today) {
      // New day — reset usage, bonus minutes, and friction warnings
      _todayUsageMinutes = 0;
      _bonusMinutesToday = 0;
      _softWarningShown = false;
      _hardWarningShown = false;
      _blockedShown = false;
      await _storage.write(key: _usageDateKey, value: today);
      await _saveLocalUsage();
      notifyListeners();
    }
  }

  // ─── Local Storage ───

  Future<void> _loadLocalCap() async {
    try {
      final isActive = await _storage.read(key: _isActiveKey);
      _isActive = isActive == 'true';

      final capStr = await _storage.read(key: _capMinutesKey);
      if (capStr != null) _capMinutes = int.tryParse(capStr) ?? 120;

      final softStr = await _storage.read(key: _softWarningKey);
      if (softStr != null) _softWarningPercent = int.tryParse(softStr) ?? 80;

      final hardStr = await _storage.read(key: _hardWarningKey);
      if (hardStr != null) _hardWarningPercent = int.tryParse(hardStr) ?? 90;

      final pinStr = await _storage.read(key: _requirePinKey);
      _requirePinToOverride = pinStr == 'true';

      await _loadLocalUsage();
    } catch (e) {
      debugPrint('HardCapProvider: failed to load local cap: $e');
    }
  }

  Future<void> _loadLocalUsage() async {
    try {
      final usageStr = await _storage.read(key: _todayUsageKey);
      if (usageStr != null) _todayUsageMinutes = int.tryParse(usageStr) ?? 0;

      final bonusStr = await _storage.read(key: _bonusMinutesKey);
      if (bonusStr != null) _bonusMinutesToday = int.tryParse(bonusStr) ?? 0;

      final softShown = await _storage.read(key: _softShownKey);
      _softWarningShown = softShown == 'true';

      final hardShown = await _storage.read(key: _hardShownKey);
      _hardWarningShown = hardShown == 'true';

      final blockedShown = await _storage.read(key: _blockedShownKey);
      _blockedShown = blockedShown == 'true';
    } catch (e) {
      debugPrint('HardCapProvider: failed to load usage: $e');
    }
  }

  Future<void> _saveLocalCap() async {
    try {
      await _storage.write(key: _isActiveKey, value: _isActive.toString());
      await _storage.write(key: _capMinutesKey, value: _capMinutes.toString());
      await _storage.write(
          key: _softWarningKey, value: _softWarningPercent.toString());
      await _storage.write(
          key: _hardWarningKey, value: _hardWarningPercent.toString());
      await _storage.write(
          key: _requirePinKey, value: _requirePinToOverride.toString());
    } catch (e) {
      debugPrint('HardCapProvider: failed to save cap: $e');
    }
  }

  Future<void> _saveLocalUsage() async {
    try {
      await _storage.write(
          key: _todayUsageKey, value: _todayUsageMinutes.toString());
      await _storage.write(
          key: _bonusMinutesKey, value: _bonusMinutesToday.toString());
      await _storage.write(
          key: _softShownKey, value: _softWarningShown.toString());
      await _storage.write(
          key: _hardShownKey, value: _hardWarningShown.toString());
      await _storage.write(
          key: _blockedShownKey, value: _blockedShown.toString());
    } catch (e) {
      debugPrint('HardCapProvider: failed to save usage: $e');
    }
  }

  Future<void> _clearLocalCap() async {
    try {
      await _storage.delete(key: _isActiveKey);
      await _storage.delete(key: _capMinutesKey);
      await _storage.delete(key: _softWarningKey);
      await _storage.delete(key: _hardWarningKey);
      await _storage.delete(key: _requirePinKey);
    } catch (e) {
      debugPrint('HardCapProvider: failed to clear cap: $e');
    }
  }
}
