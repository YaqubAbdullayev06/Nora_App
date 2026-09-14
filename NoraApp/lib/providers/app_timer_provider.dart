import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// AppTimerProvider — Manages per-app daily time limits.
/// Tracks usage against limits and enforces restrictions.
class AppTimerProvider extends ChangeNotifier {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  /// Map of packageName -> daily limit in minutes.
  final Map<String, int> _limits = {};

  /// Map of packageName -> today's used minutes.
  final Map<String, int> _usage = {};

  /// Map of packageName -> app display name.
  final Map<String, String> _appNames = {};

  /// Set of packages that have exceeded their limit today.
  final Set<String> _exceeded = {};

  /// Timer for periodic usage checks.
  Timer? _checkTimer;

  static const _limitsKey = 'app_timer_limits';
  static const _usageKey = 'app_timer_usage';
  static const _usageDateKey = 'app_timer_usage_date';

  /// Get all configured limits.
  Map<String, int> get limits => Map.unmodifiable(_limits);

  /// Get today's usage.
  Map<String, int> get usage => Map.unmodifiable(_usage);

  /// Get packages that have exceeded their limits.
  Set<String> get exceeded => Set.unmodifiable(_exceeded);

  /// Get total limited minutes used today.
  int get totalLimitedMinutes =>
      _usage.values.fold(0, (sum, m) => sum + m);

  /// Initialize the provider and load saved data.
  Future<void> initialize() async {
    await _loadLimits();
    await _loadUsage();
    _startPeriodicCheck();
    notifyListeners();
  }

  /// Set a daily time limit for an app (in minutes).
  /// Pass null or 0 to remove the limit.
  Future<void> setLimit(String packageName, String appName, int? minutes) async {
    if (minutes != null && minutes > 0) {
      _limits[packageName] = minutes;
      _appNames[packageName] = appName;
    } else {
      _limits.remove(packageName);
      _usage.remove(packageName);
      _exceeded.remove(packageName);
      _appNames.remove(packageName);
    }
    await _saveLimits();
    _checkExceeded();
    notifyListeners();
  }

  /// Remove a limit for an app.
  Future<void> removeLimit(String packageName) async {
    _limits.remove(packageName);
    _usage.remove(packageName);
    _exceeded.remove(packageName);
    _appNames.remove(packageName);
    await _saveLimits();
    notifyListeners();
  }

  /// Record usage for an app (called periodically or on app switch).
  Future<void> recordUsage(String packageName, int minutes) async {
    if (!_limits.containsKey(packageName)) return;

    final current = _usage[packageName] ?? 0;
    _usage[packageName] = current + minutes;
    await _saveUsage();
    _checkExceeded();
    notifyListeners();
  }

  /// Get remaining minutes for a package.
  int getRemaining(String packageName) {
    final limit = _limits[packageName];
    if (limit == null) return -1; // No limit
    final used = _usage[packageName] ?? 0;
    return (limit - used).clamp(0, limit);
  }

  /// Get usage progress for a package (0.0 to 1.0).
  double getProgress(String packageName) {
    final limit = _limits[packageName];
    if (limit == null || limit == 0) return 0.0;
    final used = _usage[packageName] ?? 0;
    return (used / limit).clamp(0.0, 1.0);
  }

  /// Check if a package has exceeded its limit.
  bool hasExceeded(String packageName) {
    return _exceeded.contains(packageName);
  }

  /// Get all apps with limits, sorted by usage descending.
  List<MapEntry<String, int>> getSortedLimits() {
    final entries = _limits.entries.toList();
    entries.sort((a, b) {
      final usageA = _usage[a.key] ?? 0;
      final usageB = _usage[b.key] ?? 0;
      return usageB.compareTo(usageA);
    });
    return entries;
  }

  /// Get the app name for a package.
  String getAppName(String packageName) {
    return _appNames[packageName] ?? packageName.split('.').last;
  }

  /// Check which packages have exceeded their limits.
  void _checkExceeded() {
    _exceeded.clear();
    for (final entry in _limits.entries) {
      final used = _usage[entry.key] ?? 0;
      if (used >= entry.value) {
        _exceeded.add(entry.key);
      }
    }
  }

  /// Start periodic check for usage resets and limit enforcement.
  void _startPeriodicCheck() {
    _checkTimer?.cancel();
    _checkTimer = Timer.periodic(const Duration(minutes: 1), (_) async {
      await _checkDailyReset();
    });
  }

  /// Check if we need to reset daily usage (new day).
  Future<void> _checkDailyReset() async {
    final savedDate = await _storage.read(key: _usageDateKey);
    final today = DateTime.now().toIso8601String().substring(0, 10);

    if (savedDate != today) {
      // New day — reset usage
      _usage.clear();
      _exceeded.clear();
      await _storage.write(key: _usageDateKey, value: today);
      await _saveUsage();
      notifyListeners();
    }
  }

  /// Load limits from secure storage.
  Future<void> _loadLimits() async {
    try {
      final data = await _storage.read(key: _limitsKey);
      if (data != null && data.isNotEmpty) {
        final parts = data.split('|');
        for (final part in parts) {
          final kv = part.split(':');
          if (kv.length == 2) {
            final pkg = Uri.decodeComponent(kv[0]);
            final minutes = int.tryParse(kv[1]);
            if (minutes != null && minutes > 0) {
              _limits[pkg] = minutes;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('AppTimerProvider: failed to load limits: $e');
    }
  }

  /// Save limits to secure storage.
  Future<void> _saveLimits() async {
    try {
      if (_limits.isEmpty) {
        await _storage.delete(key: _limitsKey);
        return;
      }
      final parts = _limits.entries
          .map((e) => '${Uri.encodeComponent(e.key)}:${e.value}')
          .toList();
      await _storage.write(key: _limitsKey, value: parts.join('|'));
    } catch (e) {
      debugPrint('AppTimerProvider: failed to save limits: $e');
    }
  }

  /// Load usage from secure storage.
  Future<void> _loadUsage() async {
    try {
      final date = await _storage.read(key: _usageDateKey);
      final today = DateTime.now().toIso8601String().substring(0, 10);

      if (date != today) {
        // Different day — start fresh
        _usage.clear();
        await _storage.write(key: _usageDateKey, value: today);
        return;
      }

      final data = await _storage.read(key: _usageKey);
      if (data != null && data.isNotEmpty) {
        final parts = data.split('|');
        for (final part in parts) {
          final kv = part.split(':');
          if (kv.length == 2) {
            final pkg = Uri.decodeComponent(kv[0]);
            final minutes = int.tryParse(kv[1]);
            if (minutes != null) {
              _usage[pkg] = minutes;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('AppTimerProvider: failed to load usage: $e');
    }
  }

  /// Save usage to secure storage.
  Future<void> _saveUsage() async {
    try {
      if (_usage.isEmpty) {
        await _storage.delete(key: _usageKey);
        return;
      }
      final parts = _usage.entries
          .map((e) => '${Uri.encodeComponent(e.key)}:${e.value}')
          .toList();
      await _storage.write(key: _usageKey, value: parts.join('|'));
    } catch (e) {
      debugPrint('AppTimerProvider: failed to save usage: $e');
    }
  }

  /// Get a summary of all limits.
  String getSummary() {
    if (_limits.isEmpty) return 'No app limits set';
    final total = _limits.length;
    final exceededCount = _exceeded.length;
    return '$total limits set, $exceededCount exceeded today';
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    super.dispose();
  }
}
