import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/enums/age_group.dart';
import '../core/constants/design_tokens.dart';
import '../core/theme/persona_theme.dart';
import '../services/usage_tracker_service.dart';

/// Manages persona/theme state and screen-time tracking.
class PersonaProvider extends ChangeNotifier {
  final UsageTrackerService _usageTracker = UsageTrackerService();
  Timer? _screenTimeRefreshTimer;

  AgeGroup _ageGroup;
  PersonaTheme _persona;

  int _screenTimeTodayMinutes = 0;

  PersonaProvider({AgeGroup initialAgeGroup = AgeGroup.adult})
      : _ageGroup = initialAgeGroup,
        _persona = PersonaTheme.forAgeGroup(initialAgeGroup);

  AgeGroup get ageGroup => _ageGroup;
  PersonaTheme get persona => _persona;

  int get screenTimeTodayMinutes => _screenTimeTodayMinutes;

  bool get isScreenTimeExceeded {
    if (_persona.ageGroup.screenTimeLimitMinutes == 0) return false;
    return _screenTimeTodayMinutes >= _persona.ageGroup.screenTimeLimitMinutes;
  }

  double get screenTimeProgress {
    if (_persona.ageGroup.screenTimeLimitMinutes == 0) return 0;
    return _screenTimeTodayMinutes / _persona.ageGroup.screenTimeLimitMinutes;
  }

  /// Switch persona based on age group selection.
  void setAgeGroup(AgeGroup group) {
    _ageGroup = group;
    _persona = PersonaTheme.forAgeGroup(group);
    DesignTokens.init(_persona);
    notifyListeners();
  }

  /// Fetch real screen time from Android's UsageStatsManager.
  Future<void> refreshScreenTime() async {
    try {
      final todayUsage = await _usageTracker.getTodayUsage();
      if (todayUsage != null) {
        _screenTimeTodayMinutes = todayUsage.totalScreenTimeMinutes;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to refresh screen time: $e');
    }
  }

  /// Start periodic refresh of screen time data.
  void startScreenTimeRefresh() {
    _screenTimeRefreshTimer?.cancel();
    _screenTimeRefreshTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => refreshScreenTime(),
    );
  }

  @override
  void dispose() {
    _screenTimeRefreshTimer?.cancel();
    super.dispose();
  }
}
