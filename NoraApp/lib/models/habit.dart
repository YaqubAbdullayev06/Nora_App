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
    // M38: defensive casts — server fields may arrive as String/double/null
    // and a malformed created_at must not crash the whole habit list.
    final target = (json['target_per_day'] as num?)?.toInt() ?? 1;
    final active = json['is_active'];
    return Habit(
      id: (json['id'] as num?)?.toInt() ?? int.tryParse('${json['id']}') ?? 0,
      name: json['name'] is String ? json['name'] as String : '',
      category: json['category'] is String ? json['category'] as String : 'general',
      icon: json['icon'] is String ? json['icon'] as String : 'check_circle',
      color: json['color'] is String ? json['color'] as String : '#4CAF50',
      screenTimeMinutes: (json['screen_time_minutes'] as num?)?.toInt() ?? 15,
      // Guard: target < 1 would make isCompletedToday always true
      targetPerDay: target > 0 ? target : 1,
      isActive: active is bool ? active : true,
      completionsToday: (json['completions_today'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] is String
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  bool get isCompletedToday => completionsToday >= targetPerDay;

  double get todayProgress {
    if (targetPerDay <= 0) return 0.0;
    return (completionsToday / targetPerDay).clamp(0.0, 1.0);
  }
}
