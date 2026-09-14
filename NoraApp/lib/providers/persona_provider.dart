import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/enums/age_group.dart';
import '../core/constants/design_tokens.dart';
import '../core/theme/persona_theme.dart';
import '../services/screentime_service.dart';
import '../models/app_info.dart';

/// Manages persona/theme state and screen-time tracking.
///
/// Uses the cross-platform ScreenTimeService for usage data.
/// Supports both Android (UsageStatsManager) and iOS (DeviceActivity).
class PersonaProvider extends ChangeNotifier {
  final ScreenTimeService _screenTimeService = ScreenTimeService();
  Timer? _screenTimeRefreshTimer;

  AgeGroup _ageGroup;
  PersonaTheme _persona;

  int _screenTimeTodayMinutes = 0;
  ScreenTimePermission _permissionStatus = ScreenTimePermission.denied;
  ScreenTimeInsights? _insights;
  bool _isInitialized = false;

  PersonaProvider({AgeGroup initialAgeGroup = AgeGroup.adult})
      : _ageGroup = initialAgeGroup,
        _persona = PersonaTheme.forAgeGroup(initialAgeGroup);

  AgeGroup get ageGroup => _ageGroup;
  PersonaTheme get persona => _persona;

  int get screenTimeTodayMinutes => _screenTimeTodayMinutes;
  ScreenTimePermission get permissionStatus => _permissionStatus;
  ScreenTimeInsights? get insights => _insights;
  bool get isInitialized => _isInitialized;

  bool get isScreenTimeExceeded {
    if (_persona.ageGroup.screenTimeLimitMinutes == 0) return false;
    return _screenTimeTodayMinutes >= _persona.ageGroup.screenTimeLimitMinutes;
  }

  double get screenTimeProgress {
    if (_persona.ageGroup.screenTimeLimitMinutes == 0) return 0;
    return _screenTimeTodayMinutes / _persona.ageGroup.screenTimeLimitMinutes;
  }

  String get screenTimeStatus {
    if (isScreenTimeExceeded) return 'exceeded';
    if (screenTimeProgress > 0.8) return 'warning';
    return 'normal';
  }

  // ─── Initialization ───

  /// Initialize the screen time service and check permissions.
  Future<void> initialize() async {
    if (_isInitialized) return;

    await _screenTimeService.initialize();
    _permissionStatus = await _screenTimeService.checkPermission();

    if (_permissionStatus == ScreenTimePermission.granted) {
      await refreshScreenTime();
      await _refreshInsights();
    }

    _isInitialized = true;
    notifyListeners();

    debugPrint('[PersonaProvider] Initialized with permission: $_permissionStatus');
  }

  // ─── Permission Management ───

  /// Request screen time permissions.
  Future<bool> requestPermission() async {
    _permissionStatus = await _screenTimeService.requestPermission();
    notifyListeners();

    if (_permissionStatus == ScreenTimePermission.granted) {
      await refreshScreenTime();
      await _refreshInsights();
      return true;
    }

    return false;
  }

  /// Open system settings for screen time permissions.
  Future<void> openSettings() async {
    await _screenTimeService.requestPermission();
  }

  // ─── Persona Management ───

  /// Switch persona based on age group selection.
  void setAgeGroup(AgeGroup group) {
    _ageGroup = group;
    _persona = PersonaTheme.forAgeGroup(group);
    DesignTokens.init(_persona);
    notifyListeners();
  }

  // ─── Screen Time Data ───

  /// Fetch real screen time from platform.
  Future<void> refreshScreenTime() async {
    if (_permissionStatus != ScreenTimePermission.granted) return;

    try {
      final todayUsage = await _screenTimeService.getTodayUsage();
      if (todayUsage != null) {
        _screenTimeTodayMinutes = todayUsage.totalScreenTimeMinutes;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to refresh screen time: $e');
    }
  }

  /// Refresh usage insights and recommendations.
  Future<void> _refreshInsights() async {
    if (_permissionStatus != ScreenTimePermission.granted) return;

    try {
      _insights = await _screenTimeService.analyzeUsagePatterns();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to refresh insights: $e');
    }
  }

  /// Get detailed usage stats for a specific period.
  Future<UsageStatsSummary?> getUsageStats({int daysBack = 7}) async {
    if (_permissionStatus != ScreenTimePermission.granted) return null;
    return await _screenTimeService.getUsageStats(daysBack: daysBack);
  }

  /// Get top apps by usage today.
  Future<List<AppUsageEntry>> getTopAppsToday() async {
    final todayUsage = await _screenTimeService.getTodayUsage();
    return todayUsage?.topApps ?? [];
  }

  // ─── Monitoring ───

  /// Start periodic refresh of screen time data.
  void startScreenTimeRefresh() {
    _screenTimeRefreshTimer?.cancel();
    _screenTimeRefreshTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _onRefreshTick(),
    );
  }

  /// Stop periodic refresh.
  void stopScreenTimeRefresh() {
    _screenTimeRefreshTimer?.cancel();
    _screenTimeRefreshTimer = null;
  }

  Future<void> _onRefreshTick() async {
    await refreshScreenTime();
    await _refreshInsights();
  }

  // ─── AI Context ───

  /// Build a context string for AI analysis.
  Future<String> buildAIContext() async {
    return await _screenTimeService.buildUsageContextForAI();
  }

  // ─── Cleanup ───

  @override
  void dispose() {
    _screenTimeRefreshTimer?.cancel();
    super.dispose();
  }
}
