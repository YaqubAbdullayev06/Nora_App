import '../models/models.dart';
import 'api_service.dart';

/// TaskDecomposer — AI-powered task breakdown into Pomodoro-sized subtasks.
///
/// Sends a broad task to the backend /ai/decompose-task endpoint
/// and receives structured subtasks with priorities and time estimates.
class TaskDecomposer {
  final ApiService _api = ApiService();

  /// Decompose a task into subtasks.
  ///
  /// Returns a [DecomposedTask] with subtasks, or null on failure.
  Future<DecomposedTask?> decompose(String task, {String ageGroup = "adult"}) async {
    try {
      final response = await _api.decomposeTask(task, ageGroup: ageGroup);

      if (response["success"] == true) {
        return DecomposedTask.fromJson(response);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}

/// A decomposed task with subtasks.
class DecomposedTask {
  final String originalTask;
  final List<DecomposedSubtask> subtasks;
  final int totalEstimatedMinutes;
  final String tip;
  final String provider;

  const DecomposedTask({
    required this.originalTask,
    required this.subtasks,
    required this.totalEstimatedMinutes,
    required this.tip,
    required this.provider,
  });

  factory DecomposedTask.fromJson(Map<String, dynamic> json) {
    return DecomposedTask(
      originalTask: json["original_task"] ?? "",
      subtasks: (json["subtasks"] as List?)
              ?.map((s) => DecomposedSubtask.fromJson(s))
              .toList() ??
          [],
      totalEstimatedMinutes: json["total_estimated_minutes"] ?? 0,
      tip: json["tip"] ?? "",
      provider: json["provider"] ?? "unknown",
    );
  }

  /// Convert to PlanTask list for integration with DailyPlan.
  List<PlanTask> toPlanTasks() {
    return subtasks.asMap().entries.map((entry) {
      final i = entry.key;
      final subtask = entry.value;
      return PlanTask(
        id: "decomposed_$i",
        title: subtask.title,
        priority: subtask.priority,
        completed: false,
      );
    }).toList();
  }
}

/// A single subtask from decomposition.
class DecomposedSubtask {
  final String title;
  final int priority;
  final int estimatedMinutes;
  final String description;

  const DecomposedSubtask({
    required this.title,
    required this.priority,
    required this.estimatedMinutes,
    required this.description,
  });

  factory DecomposedSubtask.fromJson(Map<String, dynamic> json) {
    return DecomposedSubtask(
      title: json["title"] ?? "",
      priority: json["priority"] ?? 2,
      estimatedMinutes: json["estimated_minutes"] ?? 20,
      description: json["description"] ?? "",
    );
  }

  String get priorityLabel {
    switch (priority) {
      case 1:
        return "Must do";
      case 2:
        return "Should do";
      case 3:
        return "Nice to do";
      default:
        return "Task";
    }
  }
}
