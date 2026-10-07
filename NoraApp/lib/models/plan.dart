/// Sentinel for copyWith "leave unchanged" vs "set to null".
const Object _unset = Object();

/// A single task within a daily plan.
class PlanTask {
  final String id;
  final String title;
  final int priority; // 1, 2, or 3
  final bool completed;
  final String? iconAsset;
  final DateTime? completedAt;

  const PlanTask({
    required this.id,
    required this.title,
    required this.priority,
    this.completed = false,
    this.iconAsset,
    this.completedAt,
  });

  factory PlanTask.fromJson(Map<String, dynamic> json) {
    return PlanTask(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      priority: json['priority'] ?? 1,
      completed: json['completed'] ?? false,
      iconAsset: json['iconAsset'],
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'priority': priority,
      'completed': completed,
      'iconAsset': iconAsset,
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  PlanTask copyWith({
    String? id,
    String? title,
    int? priority,
    bool? completed,
    Object? iconAsset = _unset,
    Object? completedAt = _unset,
  }) {
    return PlanTask(
      id: id ?? this.id,
      title: title ?? this.title,
      priority: priority ?? this.priority,
      completed: completed ?? this.completed,
      // M22: sentinel — plain `?? this.x` made it impossible to CLEAR these
      // fields (e.g. un-completing a task kept its completedAt timestamp)
      iconAsset: identical(iconAsset, _unset)
          ? this.iconAsset
          : iconAsset as String?,
      completedAt: identical(completedAt, _unset)
          ? this.completedAt
          : completedAt as DateTime?,
    );
  }

  String get priorityLabel {
    switch (priority) {
      case 1:
        return 'Must do';
      case 2:
        return 'Should do';
      case 3:
        return 'Nice to do';
      default:
        return 'Task';
    }
  }
}

/// A daily plan containing up to 3 prioritized tasks.
class DailyPlan {
  final String id;
  final String userId;
  final DateTime date;
  final List<PlanTask> tasks;
  final bool morningPlanned;
  final bool eveningReflected;
  final String? reflectionNote;
  final int pointsEarned;

  const DailyPlan({
    required this.id,
    required this.userId,
    required this.date,
    required this.tasks,
    this.morningPlanned = false,
    this.eveningReflected = false,
    this.reflectionNote,
    this.pointsEarned = 0,
  });

  factory DailyPlan.fromJson(Map<String, dynamic> json) {
    return DailyPlan(
      id: json['id']?.toString() ?? '',
      userId: json['userId'] ?? '',
      date: DateTime.parse(
          json['date'] ?? DateTime.now().toIso8601String()),
      tasks: (json['tasks'] as List?)
              ?.map((t) => PlanTask.fromJson(t))
              .toList() ??
          [],
      morningPlanned: json['morningPlanned'] ?? false,
      eveningReflected: json['eveningReflected'] ?? false,
      reflectionNote: json['reflectionNote'],
      pointsEarned: json['pointsEarned'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'date': date.toIso8601String(),
      'tasks': tasks.map((t) => t.toJson()).toList(),
      'morningPlanned': morningPlanned,
      'eveningReflected': eveningReflected,
      'reflectionNote': reflectionNote,
      'pointsEarned': pointsEarned,
    };
  }

  DailyPlan copyWith({
    String? id,
    String? userId,
    DateTime? date,
    List<PlanTask>? tasks,
    bool? morningPlanned,
    bool? eveningReflected,
    Object? reflectionNote = _unset,
    int? pointsEarned,
  }) {
    return DailyPlan(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      tasks: tasks ?? this.tasks,
      morningPlanned: morningPlanned ?? this.morningPlanned,
      eveningReflected: eveningReflected ?? this.eveningReflected,
      // M22: sentinel — allows clearing the note (pass null explicitly)
      reflectionNote: identical(reflectionNote, _unset)
          ? this.reflectionNote
          : reflectionNote as String?,
      pointsEarned: pointsEarned ?? this.pointsEarned,
    );
  }

  int get completedCount => tasks.where((t) => t.completed).length;
  bool get allCompleted => tasks.isNotEmpty && tasks.every((t) => t.completed);
  double get progress =>
      tasks.isEmpty ? 0.0 : completedCount / tasks.length;
}
