import 'package:flutter/foundation.dart';
import '../core/enums/age_group.dart';
import '../models/models.dart';
import 'persona_provider.dart';

/// Manages daily planning state and task completion.
class PlanProvider extends ChangeNotifier {
  final PersonaProvider _personaProvider;

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

    _todayPlan = DailyPlan(
      id: 'plan_${today.millisecondsSinceEpoch}',
      userId: _userId ?? '1',
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
      userId: _userId ?? '1',
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

    final pointsPerTask = _personaProvider.ageGroup.pointsPerTask;
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
    // TODO: Fetch real plan history from backend when endpoint is available.
    // Previously returned fabricated fake history — now returns empty.
    _planHistory = [];
    notifyListeners();
  }

  void clearAll() {
    _todayPlan = null;
    _planHistory = [];
    notifyListeners();
  }
}
