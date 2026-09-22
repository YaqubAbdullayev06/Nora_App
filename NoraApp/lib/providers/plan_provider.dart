import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/enums/age_group.dart';
import '../models/models.dart';
import 'persona_provider.dart';

/// Manages daily planning state and task completion.
class PlanProvider extends ChangeNotifier {
  final PersonaProvider _personaProvider;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const _todayKey = 'plan_today';
  static const _historyKey = 'plan_history';

  DailyPlan? _todayPlan;
  List<DailyPlan> _planHistory = [];

  PlanProvider({required PersonaProvider personaProvider})
      : _personaProvider = personaProvider;

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

  /// Set the user ID for plan creation (called after login).
  void setUserId(String? userId) {
    _userId = userId;
  }

  String? _userId;

  void loadTodayPlan() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (_todayPlan != null &&
        DateTime(_todayPlan!.date.year, _todayPlan!.date.month,
                _todayPlan!.date.day)
            .isAtSameMomentAs(today)) {
      return;
    }

    _restoreTodayFromStorage(today);
  }

  /// Restore today's plan from secure storage if it matches [today],
  /// otherwise create an empty placeholder plan for the new day.
  Future<void> _restoreTodayFromStorage(DateTime today) async {
    try {
      final raw = await _storage.read(key: _todayKey);
      if (raw != null && raw.isNotEmpty) {
        final stored = DailyPlan.fromJson(jsonDecode(raw) as Map<String, dynamic>);
        final storedDay = DateTime(stored.date.year, stored.date.month, stored.date.day);
        if (storedDay.isAtSameMomentAs(today)) {
          _todayPlan = stored;
          notifyListeners();
          return;
        }
      }
    } catch (e) {
      debugPrint('PlanProvider: failed to restore today plan: $e');
    }

    _todayPlan = DailyPlan(
      id: 'plan_${today.millisecondsSinceEpoch}',
      userId: _userId ?? 'local',
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
    final maxTasks = _personaProvider.ageGroup.maxDailyTasks;

    final tasks = <PlanTask>[];
    for (var i = 0; i < taskTitles.length && i < maxTasks; i++) {
      tasks.add(PlanTask(
        id: 'task_${today.millisecondsSinceEpoch}_$i',
        title: taskTitles[i],
        priority: i + 1,
        completed: false,
        iconAsset: _personaProvider.ageGroup.defaultTaskIcon,
      ));
    }

    _todayPlan = DailyPlan(
      id: 'plan_${today.millisecondsSinceEpoch}',
      userId: _userId ?? 'local',
      date: today,
      tasks: tasks,
      morningPlanned: true,
      eveningReflected: false,
      pointsEarned: 0,
    );
    _persistToday();
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

    final pointsPerTask = _personaProvider.ageGroup.pointsPerTask;
    final newPointsEarned =
        updatedTasks.where((t) => t.completed).length * pointsPerTask;

    _todayPlan = _todayPlan!.copyWith(
      tasks: updatedTasks,
      pointsEarned: newPointsEarned,
    );
    _persistToday();
    notifyListeners();
  }

  void submitReflection(String note) {
    if (_todayPlan == null) return;

    _todayPlan = _todayPlan!.copyWith(
      eveningReflected: true,
      reflectionNote: note,
    );

    _planHistory = [_todayPlan!, ..._planHistory];
    _persistToday();
    _persistHistory();
    notifyListeners();
  }

  void loadPlanHistory() {
    Future.microtask(_restoreHistory);
  }

  Future<void> _restoreHistory() async {
    try {
      final raw = await _storage.read(key: _historyKey);
      if (raw != null && raw.isNotEmpty) {
        final list = jsonDecode(raw) as List<dynamic>;
        _planHistory = list
            .map((e) => DailyPlan.fromJson(e as Map<String, dynamic>))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('PlanProvider: failed to restore history: $e');
    }
  }

  Future<void> _persistToday() async {
    try {
      if (_todayPlan != null) {
        await _storage.write(key: _todayKey, value: jsonEncode(_todayPlan!.toJson()));
      }
    } catch (e) {
      debugPrint('PlanProvider: failed to persist today plan: $e');
    }
  }

  Future<void> _persistHistory() async {
    try {
      await _storage.write(
        key: _historyKey,
        value: jsonEncode(_planHistory.map((p) => p.toJson()).toList()),
      );
    } catch (e) {
      debugPrint('PlanProvider: failed to persist history: $e');
    }
  }

  void clearAll() {
    _todayPlan = null;
    _planHistory = [];
    _storage.delete(key: _todayKey);
    _storage.delete(key: _historyKey);
    notifyListeners();
  }
}
