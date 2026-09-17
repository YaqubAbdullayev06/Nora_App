import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../core/enums/age_group.dart';
import '../core/constants/design_tokens.dart';
import '../core/theme/persona_theme.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/focus_protection_service.dart';
import '../services/usage_tracker_service.dart';
import '../services/screentime_service.dart';

/// AppProvider - Central state management (DEPRECATED).
///
/// **Prefer using the domain-specific providers directly:**
/// - [AuthProvider] → authentication, user profile
/// - [PersonaProvider] → age group, persona theme, screen time
/// - [TimerProvider] → timer, breaks, pomodoro
/// - [FocusProvider] → scores, sessions, streaks, achievements
/// - [PlanProvider] → daily plans, tasks
/// - [WeeklyReviewProvider] → weekly reflections and goals
/// - [AgentProvider] → AI agent capabilities
///
/// This class is kept for backward compatibility during migration.
/// It is a thin coordinator that exposes all domain state in one place.
class AppProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  final FocusProtectionService _focusProtection = FocusProtectionService();
  final ScreenTimeService _screenTimeService = ScreenTimeService();
  Timer? _screenTimeRefreshTimer;
  bool _isInitialized = false;

  // ─── Persona State ───
  AgeGroup _ageGroup = AgeGroup.adult;
  PersonaTheme _persona = PersonaTheme.adultTheme;

  AgeGroup get ageGroup => _ageGroup;
  PersonaTheme get persona => _persona;

  // ─── Auth State ───
  User? _currentUser;
  bool _isLoading = false;
  String? _error;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;

  Future<FocusProtectionStatus> requestFocusProtectionAuthorization() {
    return _focusProtection.requestAuthorization();
  }

  Future<FocusProtectionStatus> getFocusProtectionStatus() {
    return _focusProtection.getStatus();
  }

  Future<void> openFocusProtectionSettings() {
    return _focusProtection.openSettings();
  }

  Future<FocusProtectionStatus> selectFocusApps() {
    return _focusProtection.selectApps();
  }

  Future<FocusProtectionStatus> enableFocusProtection() {
    return _focusProtection.enableBlocking();
  }

  Future<FocusProtectionStatus> disableFocusProtection() {
    return _focusProtection.disableBlocking();
  }

  // ─── Feed State ───
  List<ContentItem> _feedContent = [];

  List<ContentItem> get feedContent => _feedContent;

  void claimContentReward(ContentItem item) {
    notifyListeners();
  }

  Future<Map<String, dynamic>> getAgentCapabilities() {
    return _api.getAgentCapabilities();
  }

  Future<Map<String, dynamic>> getAgentFocusStatus() {
    return _api.getAgentFocusStatus();
  }

  Future<Map<String, dynamic>> scheduleAgentFocus({
    required String startTime,
    required int durationMinutes,
    String label = 'Focus session',
  }) {
    return _api.scheduleAgentFocus(
      startTime: startTime,
      durationMinutes: durationMinutes,
      label: label,
    );
  }

  Future<Map<String, dynamic>> startAgentFocus({
    required int durationMinutes,
    String label = 'Focus session',
  }) {
    return _api.startAgentFocus(durationMinutes: durationMinutes, label: label);
  }

  Future<Map<String, dynamic>> stopAgentFocus() {
    return _api.stopAgentFocus();
  }

  Future<Map<String, dynamic>> readAgentDeviceSetting(String setting) {
    return _api.readAgentDeviceSetting(setting);
  }

  Future<Map<String, dynamic>> updateAgentDeviceSetting({
    required String setting,
    required dynamic value,
    required bool userApproved,
  }) {
    return _api.updateAgentDeviceSetting(
      setting: setting,
      value: value,
      userApproved: userApproved,
    );
  }

  Future<Map<String, dynamic>> getAgentSocialPlatforms() {
    return _api.getAgentSocialPlatforms();
  }

  Future<Map<String, dynamic>> startAgentSocialOAuth({
    required String platform,
    required String redirectUri,
  }) {
    return _api.startAgentSocialOAuth(
      platform: platform,
      redirectUri: redirectUri,
    );
  }

  Future<Map<String, dynamic>> connectAgentSocialAccount({
    required String platform,
    required String accountId,
  }) {
    return _api.connectAgentSocialAccount(
      platform: platform,
      accountId: accountId,
    );
  }

  Future<Map<String, dynamic>> postAgentSocialContent({
    required String platform,
    required String accountId,
    required String text,
  }) {
    return _api.postAgentSocialContent(
      platform: platform,
      accountId: accountId,
      text: text,
    );
  }

  // ─── App Access State ───
  bool _isAppLocked = false;
  bool get isAppLocked => _isAppLocked;

  // ─── Focus State ───
  int _focusScore = 0;
  int _totalFocusMinutes = 0;
  int _streakDays = 0;
  int _sessionsCompleted = 0;
  List<String> _achievements = [];

  int get focusScore => _focusScore;
  int get totalFocusMinutes => _totalFocusMinutes;
  int get streakDays => _streakDays;
  int get sessionsCompleted => _sessionsCompleted;
  List<String> get achievements => _achievements;

  // ─── Sessions History ───
  List<FocusSession> _sessions = [];
  List<FocusSession> get sessions => _sessions;

  // ─── Screen Time Tracking ───
  int _screenTimeTodayMinutes = 0;
  int get screenTimeTodayMinutes {
    if (!_isInitialized) init(); // fire-and-forget
    return _screenTimeTodayMinutes;
  }
  bool get isScreenTimeExceeded {
    if (_persona.ageGroup.screenTimeLimitMinutes == 0) return false;
    return _screenTimeTodayMinutes >= _persona.ageGroup.screenTimeLimitMinutes;
  }

  double get screenTimeProgress {
    if (_persona.ageGroup.screenTimeLimitMinutes == 0) return 0;
    return _screenTimeTodayMinutes / _persona.ageGroup.screenTimeLimitMinutes;
  }

  // ─── Daily Planning State ───
  DailyPlan? _todayPlan;
  List<DailyPlan> _planHistory = [];

  DailyPlan? get todayPlan => _todayPlan;
  List<DailyPlan> get planHistory => _planHistory;
  bool get hasPlannedToday => _todayPlan != null && _todayPlan!.morningPlanned;
  bool get hasReflectedToday => _todayPlan?.eveningReflected ?? false;
  int get completedTasksToday => _todayPlan?.completedCount ?? 0;
  int get totalTasksToday => _todayPlan?.tasks.length ?? 0;
  double get planProgress => _todayPlan?.progress ?? 0.0;
  int get pointsEarnedToday => _todayPlan?.pointsEarned ?? 0;

  bool get isEveningTime {
    final now = DateTime.now();
    return now.hour >= 18;
  }

  // ─── Weekly Review State ───
  WeeklyReview? _currentWeeklyReview;
  List<WeeklyReview> _weeklyReviewHistory = [];

  WeeklyReview? get currentWeeklyReview => _currentWeeklyReview;
  List<WeeklyReview> get weeklyReviewHistory => _weeklyReviewHistory;

  DateTime get _currentWeekStart {
    final now = DateTime.now();
    return now.subtract(Duration(days: now.weekday - 1));
  }

  DateTime get _currentWeekEnd {
    final start = _currentWeekStart;
    return start.add(const Duration(days: 6, hours: 23, minutes: 59));
  }

  WeeklyReview getOrCreateCurrentWeeklyReview() {
    if (_currentWeeklyReview != null &&
        _currentWeeklyReview!.weekStart == _currentWeekStart) {
      return _currentWeeklyReview!;
    }

    _currentWeeklyReview = WeeklyReview(
      id: 'review_${_currentWeekStart.millisecondsSinceEpoch}',
      weekStart: _currentWeekStart,
      weekEnd: _currentWeekEnd,
      reflections: [],
      goals: WeeklyReview.getDefaultGoals(_ageGroup),
      totalFocusMinutes: weeklyFocusMinutes.fold(0, (a, b) => a + b),
      totalSessions: _sessions
          .where((s) =>
              s.startTime.isAfter(_currentWeekStart) &&
              s.startTime
                  .isBefore(_currentWeekEnd.add(const Duration(days: 1))) &&
              s.completed)
          .length,
      totalPointsEarned: _sessions
          .where((s) =>
              s.startTime.isAfter(_currentWeekStart) &&
              s.startTime
                  .isBefore(_currentWeekEnd.add(const Duration(days: 1))) &&
              s.completed)
          .fold(0, (a, b) => a + b.pointsEarned),
      streakDays: computedStreakDays,
      createdAt: DateTime.now(),
    );
    notifyListeners();
    return _currentWeeklyReview!;
  }

  void setWeeklyMood(WeeklyMood mood) {
    final review = getOrCreateCurrentWeeklyReview();
    _currentWeeklyReview = WeeklyReview(
      id: review.id,
      weekStart: review.weekStart,
      weekEnd: review.weekEnd,
      mood: mood,
      reflections: review.reflections,
      goals: review.goals,
      totalFocusMinutes: review.totalFocusMinutes,
      totalSessions: review.totalSessions,
      totalPointsEarned: review.totalPointsEarned,
      streakDays: review.streakDays,
      aiInsight: review.aiInsight,
      createdAt: review.createdAt,
    );
    notifyListeners();
  }

  void addWeeklyReflection(String question, String answer) {
    final review = getOrCreateCurrentWeeklyReview();
    final reflection = WeeklyReflection(
      id: 'ref_${DateTime.now().millisecondsSinceEpoch}',
      question: question,
      answer: answer,
      createdAt: DateTime.now(),
    );
    _currentWeeklyReview = WeeklyReview(
      id: review.id,
      weekStart: review.weekStart,
      weekEnd: review.weekEnd,
      mood: review.mood,
      reflections: [...review.reflections, reflection],
      goals: review.goals,
      totalFocusMinutes: review.totalFocusMinutes,
      totalSessions: review.totalSessions,
      totalPointsEarned: review.totalPointsEarned,
      streakDays: review.streakDays,
      aiInsight: review.aiInsight,
      createdAt: review.createdAt,
    );
    notifyListeners();
  }

  void updateWeeklyGoalProgress(String goalId, int completedMinutes) {
    final review = getOrCreateCurrentWeeklyReview();
    final updatedGoals = review.goals.map((goal) {
      if (goal.id == goalId) {
        return goal.copyWith(
          completedMinutes: completedMinutes,
          isCompleted: completedMinutes >= goal.targetMinutes,
        );
      }
      return goal;
    }).toList();

    _currentWeeklyReview = WeeklyReview(
      id: review.id,
      weekStart: review.weekStart,
      weekEnd: review.weekEnd,
      mood: review.mood,
      reflections: review.reflections,
      goals: updatedGoals,
      totalFocusMinutes: review.totalFocusMinutes,
      totalSessions: review.totalSessions,
      totalPointsEarned: review.totalPointsEarned,
      streakDays: review.streakDays,
      aiInsight: review.aiInsight,
      createdAt: review.createdAt,
    );
    notifyListeners();
  }

  void addWeeklyGoal(String title, int targetMinutes) {
    final review = getOrCreateCurrentWeeklyReview();
    final newGoal = WeeklyGoal(
      id: 'goal_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      targetMinutes: targetMinutes,
      createdAt: _currentWeekStart,
    );
    _currentWeeklyReview = WeeklyReview(
      id: review.id,
      weekStart: review.weekStart,
      weekEnd: review.weekEnd,
      mood: review.mood,
      reflections: review.reflections,
      goals: [...review.goals, newGoal],
      totalFocusMinutes: review.totalFocusMinutes,
      totalSessions: review.totalSessions,
      totalPointsEarned: review.totalPointsEarned,
      streakDays: review.streakDays,
      aiInsight: review.aiInsight,
      createdAt: review.createdAt,
    );
    notifyListeners();
  }

  void removeWeeklyGoal(String goalId) {
    final review = getOrCreateCurrentWeeklyReview();
    _currentWeeklyReview = WeeklyReview(
      id: review.id,
      weekStart: review.weekStart,
      weekEnd: review.weekEnd,
      mood: review.mood,
      reflections: review.reflections,
      goals: review.goals.where((g) => g.id != goalId).toList(),
      totalFocusMinutes: review.totalFocusMinutes,
      totalSessions: review.totalSessions,
      totalPointsEarned: review.totalPointsEarned,
      streakDays: review.streakDays,
      aiInsight: review.aiInsight,
      createdAt: review.createdAt,
    );
    notifyListeners();
  }

  void setWeeklyAiInsight(String insight) {
    final review = getOrCreateCurrentWeeklyReview();
    _currentWeeklyReview = WeeklyReview(
      id: review.id,
      weekStart: review.weekStart,
      weekEnd: review.weekEnd,
      mood: review.mood,
      reflections: review.reflections,
      goals: review.goals,
      totalFocusMinutes: review.totalFocusMinutes,
      totalSessions: review.totalSessions,
      totalPointsEarned: review.totalPointsEarned,
      streakDays: review.streakDays,
      aiInsight: insight,
      createdAt: review.createdAt,
    );
    notifyListeners();
  }

  void saveWeeklyReview() {
    if (_currentWeeklyReview != null) {
      _weeklyReviewHistory.add(_currentWeeklyReview!);
      _currentWeeklyReview = null;
      notifyListeners();
    }
  }

  WeeklyReview? getWeeklyReviewForWeek(DateTime weekStart) {
    try {
      return _weeklyReviewHistory.firstWhere(
        (r) => r.weekStart == weekStart,
      );
    } catch (_) {
      return null;
    }
  }

  // ─── Weekly Data ───

  List<int> get weeklyFocusMinutes {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final today = DateTime(now.year, now.month, now.day);

    final List<int> minutes = List.filled(7, 0);
    for (final session in _sessions) {
      if (!session.completed) continue;
      final sessionDate = DateTime(
        session.startTime.year,
        session.startTime.month,
        session.startTime.day,
      );
      final dayIndex = sessionDate.difference(startOfWeek).inDays;
      if (dayIndex >= 0 && dayIndex < 7) {
        minutes[dayIndex] += session.durationMinutes;
      }
    }
    return minutes;
  }

  /// Returns the most used app for each day of the current week.
  /// Each entry contains [appName], [minutes], and [category].
  List<WeeklyAppUsage> get weeklyAppUsage {
    final now = DateTime.now();

    // Mock data for demo — in production this would come from UsageTrackerService
    final mockApps = [
      {'name': 'Instagram', 'category': 'social_media', 'iconPath': 'assets/images/apps/instagram.svg'},
      {'name': 'YouTube', 'category': 'entertainment', 'iconPath': 'assets/images/apps/youtube.svg'},
      {'name': 'WhatsApp', 'category': 'messaging', 'iconPath': 'assets/images/apps/whatsapp.svg'},
      {'name': 'Chrome', 'category': 'productivity', 'iconPath': 'assets/images/apps/chrome.svg'},
      {'name': 'TikTok', 'category': 'social_media', 'iconPath': 'assets/images/apps/tiktok.svg'},
      {'name': 'Spotify', 'category': 'entertainment', 'iconPath': 'assets/images/apps/spotify.svg'},
      {'name': 'Telegram', 'category': 'messaging', 'iconPath': 'assets/images/apps/telegram.svg'},
    ];

    final nowDay = now.weekday - 1; // 0=Mon, 6=Sun
    final List<WeeklyAppUsage> result = [];

    for (var i = 0; i < 7; i++) {
      if (i > nowDay) {
        // Future days — no data
        result.add(WeeklyAppUsage(dayIndex: i, appName: '', minutes: 0, category: '', iconPath: ''));
      } else {
        // Pseudo-random but deterministic based on day + session count
        final seed = (i * 7 + _sessions.length) % mockApps.length;
        final app = mockApps[seed];
        final baseMinutes = 30 + ((i * 13 + _sessions.length * 3) % 120);
        result.add(WeeklyAppUsage(
          dayIndex: i,
          appName: app['name']!,
          minutes: i == nowDay ? (baseMinutes * 0.6).toInt() : baseMinutes,
          category: app['category']!,
          iconPath: app['iconPath']!,
        ));
      }
    }
    return result;
  }

  int get computedStreakDays {
    if (_sessions.isEmpty) return 0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final completedDates = _sessions
        .where((s) => s.completed)
        .map((s) =>
            DateTime(s.startTime.year, s.startTime.month, s.startTime.day))
        .toSet()
      ..removeWhere((d) => d.isAfter(today));

    if (completedDates.isEmpty) return 0;

    final yesterday = today.subtract(const Duration(days: 1));
    if (!completedDates.contains(today) &&
        !completedDates.contains(yesterday)) {
      return 0;
    }

    int streak = 0;
    DateTime checkDate = completedDates.contains(today) ? today : yesterday;
    while (completedDates.contains(checkDate)) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }
    return streak;
  }

  // ─── Initialization ───

  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;

    _totalTimerSeconds = _persona.ageGroup.defaultFocusMinutes * 60;
    _timerSeconds = _totalTimerSeconds;

    await refreshScreenTime();
    _startScreenTimeRefresh();

    notifyListeners();
  }

  Future<void> refreshScreenTime() async {
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

  void _startScreenTimeRefresh() {
    _screenTimeRefreshTimer?.cancel();
    _screenTimeRefreshTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => refreshScreenTime(),
    );
  }

  void setAgeGroup(AgeGroup group) {
    _ageGroup = group;
    _persona = PersonaTheme.forAgeGroup(group);
    DesignTokens.init(_persona);
    if (!_isTimerRunning) {
      _totalTimerSeconds = group.defaultFocusMinutes * 60;
      _timerSeconds = _totalTimerSeconds;
    }
    notifyListeners();
  }

  // ─── Auth Actions ───

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _api.login(email: email, password: password);
      _currentUser = User.fromJson(data['user']);
      setAgeGroup(_currentUser!.ageGroup);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String email, String name, String password,
      {AgeGroup ageGroup = AgeGroup.adult}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _api.register(
        email: email,
        name: name,
        password: password,
      );
      _currentUser = User.fromJson(data['user']);
      setAgeGroup(ageGroup);
      _currentUser = _currentUser!.copyWith(ageGroup: ageGroup);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void logout() {
    unlockApp();
    _currentUser = null;
    _api.setToken(null);
    _focusScore = 0;
    _totalFocusMinutes = 0;
    _streakDays = 0;
    _sessionsCompleted = 0;
    _achievements = [];
    _sessions = [];
    _screenTimeRefreshTimer?.cancel();
    _screenTimeTodayMinutes = 0;
    notifyListeners();
  }

  void lockApp() {
    if (_isAppLocked) return;
    pauseTimer();
    _isAppLocked = true;
    notifyListeners();
  }

  void unlockApp() {
    if (!_isAppLocked) return;
    _isAppLocked = false;
    notifyListeners();
  }

  // ─── Timer Actions ───

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
        (minutes * 10 * _persona.ageGroup.pointsMultiplier).toInt();
    _focusScore += points;
    _totalFocusMinutes += minutes;
    _sessionsCompleted++;
    _completedSessionsInCycle++;

    final now = DateTime.now();
    _sessions.add(FocusSession(
      id: 'session_${now.millisecondsSinceEpoch}',
      startTime: now.subtract(Duration(seconds: _totalTimerSeconds)),
      endTime: now,
      durationMinutes: minutes,
      pointsEarned: points,
      completed: true,
    ));

    _streakDays = computedStreakDays;
    _checkAchievements();
    _vibrate();

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

    _timerSeconds = _persona.ageGroup.defaultFocusMinutes * 60;
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

  void _vibrate() {
    try {
      HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  void completeTimer() {
    _timerComplete();
  }

  // ─── Focus Actions ───

  void addFocusTime(int minutes) {
    _totalFocusMinutes += minutes;
    final points =
        (minutes * 10 * _persona.ageGroup.pointsMultiplier).toInt();
    _focusScore += points;
    _sessionsCompleted++;

    final now = DateTime.now();
    _sessions.add(FocusSession(
      id: 'session_${now.millisecondsSinceEpoch}',
      startTime: now.subtract(Duration(minutes: minutes)),
      endTime: now,
      durationMinutes: minutes,
      pointsEarned: points,
      completed: true,
    ));

    _streakDays = computedStreakDays;
    _checkAchievements();
    notifyListeners();
  }

  void updateStreak(int days) {
    _streakDays = days;
    notifyListeners();
  }

  void addAchievement(String achievement) {
    if (!_achievements.contains(achievement)) {
      _achievements.add(achievement);
      notifyListeners();
    }
  }

  void _checkAchievements() {
    if (_sessionsCompleted >= 1 && !_achievements.contains('First Focus')) {
      _achievements.add('First Focus');
    }
    if (_streakDays >= 3 && !_achievements.contains('3-Day Streak')) {
      _achievements.add('3-Day Streak');
    }
    if (_totalFocusMinutes >= 60 && !_achievements.contains('Early Bird')) {
      _achievements.add('Early Bird');
    }
    if (_sessionsCompleted >= 10 && !_achievements.contains('Focus Master')) {
      _achievements.add('Focus Master');
    }
    if (_focusScore >= 1000 && !_achievements.contains('High Scorer')) {
      _achievements.add('High Scorer');
    }
    if (!_achievements.contains('Lifelong Learner') && _focusScore >= 2500) {
      _achievements.add('Lifelong Learner');
    }
  }

  void updateProfile({required String name}) {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(name: name);
    } else {
      _currentUser = User(
        id: '1',
        email: 'explorer@nora.app',
        name: name,
        ageGroup: _ageGroup,
        createdAt: DateTime.now(),
      );
    }
    notifyListeners();
  }

  // ─── Daily Planning Actions ───

  void loadTodayPlan() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (_todayPlan != null &&
        DateTime(_todayPlan!.date.year, _todayPlan!.date.month,
                _todayPlan!.date.day)
            .isAtSameMomentAs(today)) {
      return;
    }

    _todayPlan = DailyPlan(
      id: 'plan_${today.millisecondsSinceEpoch}',
      userId: _currentUser?.id ?? '1',
      date: today,
      tasks: [],
      morningPlanned: false,
      eveningReflected: false,
      pointsEarned: 0,
    );
    notifyListeners();
  }

  void createDailyPlan(List<String> taskTitles) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final maxTasks = _ageGroup.maxDailyTasks;

    final tasks = <PlanTask>[];
    for (var i = 0; i < taskTitles.length && i < maxTasks; i++) {
      tasks.add(PlanTask(
        id: 'task_${today.millisecondsSinceEpoch}_$i',
        title: taskTitles[i],
        priority: i + 1,
        completed: false,
        iconAsset: _ageGroup.defaultTaskIcon,
      ));
    }

    _todayPlan = DailyPlan(
      id: 'plan_${today.millisecondsSinceEpoch}',
      userId: _currentUser?.id ?? '1',
      date: today,
      tasks: tasks,
      morningPlanned: true,
      eveningReflected: false,
      pointsEarned: 0,
    );
    notifyListeners();
  }

  void toggleTask(String taskId) {
    if (_todayPlan == null) return;

    final updatedTasks = _todayPlan!.tasks.map((task) {
      if (task.id == taskId) {
        final nowCompleted = !task.completed;
        return task.copyWith(
          completed: nowCompleted,
          completedAt: nowCompleted ? DateTime.now() : null,
        );
      }
      return task;
    }).toList();

    final pointsPerTask = _ageGroup.pointsPerTask;
    final newPointsEarned =
        updatedTasks.where((t) => t.completed).length * pointsPerTask;

    _todayPlan = _todayPlan!.copyWith(
      tasks: updatedTasks,
      pointsEarned: newPointsEarned,
    );
    notifyListeners();
  }

  void submitReflection(String note) {
    if (_todayPlan == null) return;

    _todayPlan = _todayPlan!.copyWith(
      eveningReflected: true,
      reflectionNote: note,
    );

    _planHistory = [_todayPlan!, ..._planHistory];
    notifyListeners();
  }

  void loadPlanHistory() {
    final now = DateTime.now();
    final history = <DailyPlan>[];

    for (var i = 1; i <= 7; i++) {
      final date = now.subtract(Duration(days: i));
      final dayOnly = DateTime(date.year, date.month, date.day);
      final completedCount = (i % 3) + 1;
      final totalTasks = 3;
      final points = completedCount * _ageGroup.pointsPerTask;

      final tasks = List.generate(totalTasks, (index) {
        final isCompleted = index < completedCount;
        return PlanTask(
          id: 'history_task_${dayOnly.millisecondsSinceEpoch}_$index',
          title: _getMockTaskTitle(index),
          priority: index + 1,
          completed: isCompleted,
          completedAt:
              isCompleted ? dayOnly.add(const Duration(hours: 12)) : null,
        );
      });

      history.add(DailyPlan(
        id: 'plan_${dayOnly.millisecondsSinceEpoch}',
        userId: _currentUser?.id ?? '1',
        date: dayOnly,
        tasks: tasks,
        morningPlanned: true,
        eveningReflected: i % 2 == 0,
        pointsEarned: points,
      ));
    }

    _planHistory = history;
    notifyListeners();
  }

  String _getMockTaskTitle(int index) {
    switch (_ageGroup) {
      case AgeGroup.baby:
        return ['Color time', 'Story time', 'Play time'][index % 3];
      case AgeGroup.child:
        return ['Color time', 'Story time', 'Play time'][index % 3];
      case AgeGroup.kid:
        return ['Math homework', 'Read a chapter', 'Practice guitar'][index % 3];
      case AgeGroup.teen:
        return ['Study for test', 'Finish project', 'Go for a run'][index % 3];
      case AgeGroup.adult:
        return ['Finish report', 'Exercise', 'Meal prep'][index % 3];
    }
  }

  // ─── Cleanup ───

  @override
  void dispose() {
    _timer?.cancel();
    _screenTimeRefreshTimer?.cancel();
    super.dispose();
  }
}
