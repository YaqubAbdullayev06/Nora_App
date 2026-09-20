/// Habit — A real-world activity that earns screen time when completed.
class Habit {
  final int id;
  final String name;
  final String category;
  final String icon;
  final String color;
  final int screenTimeMinutes;
  final int targetPerDay;
  final bool isActive;
  final int completionsToday;
  final DateTime? createdAt;

  const Habit({
    required this.id,
    required this.name,
    this.category = 'general',
    this.icon = 'check_circle',
    this.color = '#4CAF50',
    this.screenTimeMinutes = 15,
    this.targetPerDay = 1,
    this.isActive = true,
    this.completionsToday = 0,
    this.createdAt,
  });

  factory Habit.fromJson(Map<String, dynamic> json) {
    return Habit(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      category: json['category'] ?? 'general',
      icon: json['icon'] ?? 'check_circle',
      color: json['color'] ?? '#4CAF50',
      screenTimeMinutes: json['screen_time_minutes'] ?? 15,
      targetPerDay: json['target_per_day'] ?? 1,
      isActive: json['is_active'] ?? true,
      completionsToday: json['completions_today'] ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  bool get isCompletedToday => completionsToday >= targetPerDay;

  double get todayProgress {
    if (targetPerDay <= 0) return 0.0;
    return (completionsToday / targetPerDay).clamp(0.0, 1.0);
  }
}
