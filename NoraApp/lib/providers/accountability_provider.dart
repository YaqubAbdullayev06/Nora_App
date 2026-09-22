import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/models.dart';
import '../services/api_service.dart';

/// Manages accountability lock state — the guardian-set PIN that the user cannot override.
///
/// Security model:
/// - PIN hash stored locally in FlutterSecureStorage for instant offline verification
/// - Backend stores backup hash for recovery and multi-device
/// - `_isVerified` resets on every app restart (must verify each session)
/// - Rate limiting: 3 failed attempts → 5-minute local cooldown
class AccountabilityProvider extends ChangeNotifier {
  final ApiService _api;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // ─── State ───
  bool _isInitialized = false;
  bool _isLockActive = false;
  String? _guardianName;
  DateTime? _lockCreatedAt;
  DateTime? _lockExpiresAt;
  bool _isExpired = false;

  /// Whether user has entered correct PIN this session.
  bool _isVerified = false;

  /// Failed verify attempts this session.
  int _verifyAttempts = 0;

  /// Whether in cooldown after too many failed attempts.
  bool _isCooldown = false;
  Timer? _cooldownTimer;

  /// Whether setup flow is in progress.
  bool _setupInProgress = false;

  /// Error message for UI.
  String? _error;

  // ─── Storage Keys ───
  static const _guardianNameKey = 'accountability_guardian_name';
  static const _expiresAtKey = 'accountability_expires_at';
  static const _isLockActiveKey = 'accountability_is_active';

  static const int _maxAttempts = 3;
  static const int _cooldownMinutes = 5;

  // ─── Getters ───
  bool get isLockActive {
    if (!_isInitialized) initialize(); // fire-and-forget
    return _isLockActive;
  }
  String? get guardianName => _guardianName;
  DateTime? get lockCreatedAt => _lockCreatedAt;
  DateTime? get lockExpiresAt => _lockExpiresAt;
  bool get isExpired => _isExpired;
  bool get isVerified => _isVerified;
  bool get isCooldown => _isCooldown;
  bool get setupInProgress => _setupInProgress;
  String? get error => _error;
  int get verifyAttempts => _verifyAttempts;
  int get remainingAttempts => _maxAttempts - _verifyAttempts;

  /// Whether the user can currently override a block/skip.
  bool get canOverride => _isLockActive ? _isVerified && !_isCooldown : true;

  /// Lock status model for UI.
  AccountabilityLock get lockStatus => AccountabilityLock(
        isActive: _isLockActive,
        guardianName: _guardianName,
        createdAt: _lockCreatedAt,
        expiresAt: _lockExpiresAt,
        isExpired: _isExpired,
      );

  AccountabilityProvider({ApiService? api}) : _api = api ?? ApiService();

  /// Initialize — loads lock status from local storage and backend.
  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;
    await _loadLocalLock();
    if (_isLockActive) {
      _checkExpiry();
      // Sync with backend in background
      _syncWithBackend();
    }
    notifyListeners();
  }

  /// Setup a new accountability lock.
  /// [currentPin] is required when replacing an active (non-expired) lock.
  Future<bool> setupLock({
    required String pin,
    required String guardianName,
    int? lockDurationDays,
    String? currentPin,
  }) async {
    _setupInProgress = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.setupAccountabilityLock(
        pin: pin,
        guardianName: guardianName,
        lockDurationDays: lockDurationDays,
        currentPin: currentPin,
      );

      if (response['success'] == true) {
        final lockData = response['lock'] as Map<String, dynamic>;
        _isLockActive = lockData['is_active'] ?? true;
        _guardianName = lockData['guardian_name'] ?? guardianName;
        _lockCreatedAt = lockData['created_at'] != null
            ? DateTime.parse(lockData['created_at'])
            : DateTime.now();
        _lockExpiresAt = lockData['expires_at'] != null
            ? DateTime.parse(lockData['expires_at'])
            : null;

        await _saveLocalLock();
        _setupInProgress = false;
        notifyListeners();
        return true;
      }

      _error = 'Setup failed';
      _setupInProgress = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _setupInProgress = false;
      notifyListeners();
      return false;
    }
  }

  /// Verify the PIN. Returns true if correct.
  Future<bool> verifyPin(String pin) async {
    if (_isCooldown) return false;
    if (!_isLockActive) return true;

    _error = null;
    notifyListeners();

    try {
      final response = await _api.verifyAccountabilityLock(pin: pin);

      if (response['success'] == true && response['verified'] == true) {
        _isVerified = true;
        _verifyAttempts = 0;
        notifyListeners();
        return true;
      }

      _handleFailedAttempt();
      return false;
    } catch (e) {
      _handleFailedAttempt();
      return false;
    }
  }

  void _handleFailedAttempt() {
    _verifyAttempts++;
    if (_verifyAttempts >= _maxAttempts) {
      _isCooldown = true;
      _error = 'Too many attempts. Try again in $_cooldownMinutes minutes.';
      _startCooldown();
    } else {
      _error = 'Incorrect PIN. ${_maxAttempts - _verifyAttempts} attempts remaining.';
    }
    notifyListeners();
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer(const Duration(minutes: _cooldownMinutes), () {
      _isCooldown = false;
      _verifyAttempts = 0;
      _error = null;
      notifyListeners();
    });
  }

  /// Unlink the lock (requires PIN).
  Future<bool> unlinkLock(String pin) async {
    _error = null;
    notifyListeners();

    try {
      final response = await _api.unlinkAccountabilityLock(pin: pin);

      if (response['success'] == true) {
        _isLockActive = false;
        _guardianName = null;
        _lockCreatedAt = null;
        _lockExpiresAt = null;
        _isExpired = false;
        _isVerified = false;
        await _clearLocalLock();
        notifyListeners();
        return true;
      }

      _error = 'Failed to unlink';
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Reset session verification (call on app restart).
  void resetSession() {
    _isVerified = false;
    _verifyAttempts = 0;
    _isCooldown = false;
    _cooldownTimer?.cancel();
    _error = null;
    notifyListeners();
  }

  /// Clear error state.
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ─── Local Storage ───

  Future<void> _loadLocalLock() async {
    try {
      final isActive = await _storage.read(key: _isLockActiveKey);
      _isLockActive = isActive == 'true';
      _guardianName = await _storage.read(key: _guardianNameKey);
      final expiresStr = await _storage.read(key: _expiresAtKey);
      if (expiresStr != null) {
        _lockExpiresAt = DateTime.tryParse(expiresStr);
      }
    } catch (e) {
      debugPrint('AccountabilityProvider: failed to load local lock: $e');
    }
  }

  Future<void> _saveLocalLock() async {
    try {
      await _storage.write(
          key: _isLockActiveKey, value: _isLockActive.toString());
      if (_guardianName != null) {
        await _storage.write(key: _guardianNameKey, value: _guardianName!);
      }
      if (_lockExpiresAt != null) {
        await _storage.write(
            key: _expiresAtKey, value: _lockExpiresAt!.toIso8601String());
      }
    } catch (e) {
      debugPrint('AccountabilityProvider: failed to save local lock: $e');
    }
  }

  Future<void> _clearLocalLock() async {
    try {
      await _storage.delete(key: _isLockActiveKey);
      await _storage.delete(key: _guardianNameKey);
      await _storage.delete(key: _expiresAtKey);
    } catch (e) {
      debugPrint('AccountabilityProvider: failed to clear local lock: $e');
    }
  }

  void _checkExpiry() {
    if (_lockExpiresAt != null && DateTime.now().isAfter(_lockExpiresAt!)) {
      _isExpired = true;
      _isLockActive = false;
    }
  }

  Future<void> _syncWithBackend() async {
    try {
      final response = await _api.getAccountabilityStatus();
      final lock = AccountabilityLock.fromJson(response);
      _isLockActive = lock.isActive;
      _guardianName = lock.guardianName;
      _isExpired = lock.isExpired;
      if (lock.expiresAt != null) _lockExpiresAt = lock.expiresAt;
      await _saveLocalLock();
      notifyListeners();
    } catch (e) {
      // Backend unavailable — rely on local state
      debugPrint('AccountabilityProvider: backend sync failed: $e');
    }
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }
}
