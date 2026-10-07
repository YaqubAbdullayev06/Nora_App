import '../core/enums/age_group.dart';
import '../core/utils/week_utils.dart';

/// Mood options for weekly review.
enum WeeklyMood {
  amazing,
  good,
  okay,
  tough,
  rough;

  String get assetPath {
    switch (this) {
      case WeeklyMood.amazing:
        return 'assets/images/moods/mood_amazing.svg';
      case WeeklyMood.good:
        return 'assets/images/moods/mood_good.svg';
      case WeeklyMood.okay:
        return 'assets/images/moods/mood_okay.svg';
      case WeeklyMood.tough:
        return 'assets/images/moods/mood_tough.svg';
      case WeeklyMood.rough:
        return 'assets/images/moods/mood_rough.svg';
    }
  }

  String get label {
    switch (this) {
      case WeeklyMood.amazing:
        return 'Amazing';
      case WeeklyMood.good:
        return 'Good';
      case WeeklyMood.okay:
        return 'Okay';
      case WeeklyMood.tough:
        return 'Tough';
      case WeeklyMood.rough:
        return 'Rough';
    }
  }

  int get colorValue {
    switch (this) {
      case WeeklyMood.amazing:
        return 0xFFFFD93D; // Gold/Yellow
      case WeeklyMood.good:
        return 0xFF60A5FA; // Blue
      case WeeklyMood.okay:
        return 0xFFA78BFA; // Purple
      case WeeklyMood.tough:
        return 0xFF93C5FD; // Light Blue
      case WeeklyMood.rough:
        return 0xFF6B8DB5; // Muted Blue
    }
  }
}

/// A reflection entry for weekly review.
class WeeklyReflection {
  final String id;
  final String question;
  final String answer;
  final DateTime createdAt;

  const WeeklyReflection({
    required this.id,
    required this.question,
    required this.answer,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'answer': answer,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory WeeklyReflection.fromJson(Map<String, dynamic> json) {
    return WeeklyReflection(
      id: json['id']?.toString() ?? '',
      question: json['question'] is String ? json['question'] as String : '',
      answer: json['answer'] is String ? json['answer'] as String : '',
      createdAt: json['createdAt'] is String
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

/// A weekly goal.
class WeeklyGoal {
  final String id;
  final String title;
  final int targetMinutes;
  final int completedMinutes;
  final bool isCompleted;
  final DateTime createdAt;

  const WeeklyGoal({
    required this.id,
    required this.title,
    required this.targetMinutes,
    this.completedMinutes = 0,
    this.isCompleted = false,
    required this.createdAt,
  });

  double get progress =>
      targetMinutes > 0 ? (completedMinutes / targetMinutes).clamp(0.0, 1.0) : 0.0;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'targetMinutes': targetMinutes,
      'completedMinutes': completedMinutes,
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory WeeklyGoal.fromJson(Map<String, dynamic> json) {
    return WeeklyGoal(
      id: json['id']?.toString() ?? '',
      title: json['title'] is String ? json['title'] as String : '',
      targetMinutes: (json['targetMinutes'] as num?)?.toInt() ?? 0,
      completedMinutes: (json['completedMinutes'] as num?)?.toInt() ?? 0,
      isCompleted: json['isCompleted'] == true,
      createdAt: json['createdAt'] is String
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  WeeklyGoal copyWith({
    String? id,
    String? title,
    int? targetMinutes,
    int? completedMinutes,
    bool? isCompleted,
    DateTime? createdAt,
  }) {
    return WeeklyGoal(
      id: id ?? this.id,
      title: title ?? this.title,
      targetMinutes: targetMinutes ?? this.targetMinutes,
      completedMinutes: completedMinutes ?? this.completedMinutes,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Complete weekly review summary.
class WeeklyReview {
  final String id;
  final DateTime weekStart;
  final DateTime weekEnd;
  final WeeklyMood? mood;
  final List<WeeklyReflection> reflections;
  final List<WeeklyGoal> goals;
  final int totalFocusMinutes;
  final int totalSessions;
  final int totalPointsEarned;
  final int streakDays;
  final String? aiInsight;
  final DateTime createdAt;

  const WeeklyReview({
    required this.id,
    required this.weekStart,
    required this.weekEnd,
    this.mood,
    this.reflections = const [],
    this.goals = const [],
    this.totalFocusMinutes = 0,
    this.totalSessions = 0,
    this.totalPointsEarned = 0,
    this.streakDays = 0,
    this.aiInsight,
    required this.createdAt,
  });

  static List<String> getReflectionPrompts(AgeGroup ageGroup) {
    switch (ageGroup) {
      case AgeGroup.baby:
        return [
          'What made you happy this week?',
          'What was your favorite thing to learn?',
          'What do you want to learn next week?',
        ];
      case AgeGroup.child:
        return [
          'What made you smile this week?',
          'What was fun to learn about?',
          'What do you want to try next week?',
        ];
      case AgeGroup.kid:
        return [
          'What was the coolest thing you learned this week?',
          'What was challenging and how did you handle it?',
          'What are you most proud of this week?',
          'What do you want to get better at next week?',
        ];
      case AgeGroup.teen:
        return [
          'What went well this week with your focus?',
          'What distracted you the most?',
          'How did you handle stress or pressure?',
          'What would you do differently next week?',
          'What habit do you want to build or break?',
        ];
      case AgeGroup.adult:
        return [
          'What were your biggest wins this week?',
          'What tasks did you procrastinate on?',
          'How was your work-life balance?',
          'What energy management strategies worked?',
          'What will you commit to improving next week?',
          'Rate your overall productivity (1-10).',
        ];
    }
  }

  static List<WeeklyGoal> getDefaultGoals(AgeGroup ageGroup) {
    // M1: midnight-truncated Monday, not `now.subtract(Duration(...))` — the
    // goal createdAt stamps should land on the same boundary the review uses.
    final goalWeekStart = startOfWeek(DateTime.now());

    switch (ageGroup) {
      case AgeGroup.baby:
        return [
          WeeklyGoal(id: 'goal_1', title: 'Learning Time', targetMinutes: 15, createdAt: goalWeekStart),
          WeeklyGoal(id: 'goal_2', title: 'Play & Explore', targetMinutes: 20, createdAt: goalWeekStart),
        ];
      case AgeGroup.child:
        return [
          WeeklyGoal(id: 'goal_1', title: 'Fun Learning', targetMinutes: 20, createdAt: goalWeekStart),
          WeeklyGoal(id: 'goal_2', title: 'Creative Play', targetMinutes: 25, createdAt: goalWeekStart),
        ];
      case AgeGroup.kid:
        return [
          WeeklyGoal(id: 'goal_1', title: 'Study Focus', targetMinutes: 60, createdAt: goalWeekStart),
          WeeklyGoal(id: 'goal_2', title: 'Reading Time', targetMinutes: 30, createdAt: goalWeekStart),
          WeeklyGoal(id: 'goal_3', title: 'Creative Activities', targetMinutes: 20, createdAt: goalWeekStart),
        ];
      case AgeGroup.teen:
        return [
          WeeklyGoal(id: 'goal_1', title: 'Deep Study Sessions', targetMinutes: 120, createdAt: goalWeekStart),
          WeeklyGoal(id: 'goal_2', title: 'Skill Practice', targetMinutes: 60, createdAt: goalWeekStart),
          WeeklyGoal(id: 'goal_3', title: 'Mindfulness', targetMinutes: 30, createdAt: goalWeekStart),
        ];
      case AgeGroup.adult:
        return [
          WeeklyGoal(id: 'goal_1', title: 'Deep Work Hours', targetMinutes: 300, createdAt: goalWeekStart),
          WeeklyGoal(id: 'goal_2', title: 'Learning & Growth', targetMinutes: 120, createdAt: goalWeekStart),
          WeeklyGoal(id: 'goal_3', title: 'Exercise & Wellness', targetMinutes: 150, createdAt: goalWeekStart),
          WeeklyGoal(id: 'goal_4', title: 'Side Projects', targetMinutes: 60, createdAt: goalWeekStart),
        ];
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'weekStart': weekStart.toIso8601String(),
      'weekEnd': weekEnd.toIso8601String(),
      'mood': mood?.index,
      'reflections': reflections.map((r) => r.toJson()).toList(),
      'goals': goals.map((g) => g.toJson()).toList(),
      'totalFocusMinutes': totalFocusMinutes,
      'totalSessions': totalSessions,
      'totalPointsEarned': totalPointsEarned,
      'streakDays': streakDays,
      'aiInsight': aiInsight,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory WeeklyReview.fromJson(Map<String, dynamic> json) {
    // M38: defensive — an out-of-range mood index or malformed date used to
    // throw RangeError/FormatException and blank out the whole review list.
    DateTime? tryParse(dynamic v) => v is String ? DateTime.tryParse(v) : null;
    WeeklyMood? mood;
    final rawMood = json['mood'];
    if (rawMood is num) {
      final idx = rawMood.toInt();
      if (idx >= 0 && idx < WeeklyMood.values.length) {
        mood = WeeklyMood.values[idx];
      }
    }
    return WeeklyReview(
      id: json['id']?.toString() ?? '',
      weekStart: tryParse(json['weekStart']) ?? DateTime.now(),
      weekEnd: tryParse(json['weekEnd']) ?? DateTime.now(),
      mood: mood,
      reflections: (json['reflections'] as List?)
              ?.whereType<Map>()
              .map((r) =>
                  WeeklyReflection.fromJson(Map<String, dynamic>.from(r)))
              .toList() ??
          [],
      goals: (json['goals'] as List?)
              ?.whereType<Map>()
              .map((g) => WeeklyGoal.fromJson(Map<String, dynamic>.from(g)))
              .toList() ??
          [],
      totalFocusMinutes: (json['totalFocusMinutes'] as num?)?.toInt() ?? 0,
      totalSessions: (json['totalSessions'] as num?)?.toInt() ?? 0,
      totalPointsEarned: (json['totalPointsEarned'] as num?)?.toInt() ?? 0,
      streakDays: (json['streakDays'] as num?)?.toInt() ?? 0,
      aiInsight: json['aiInsight'] is String ? json['aiInsight'] as String : null,
      createdAt: tryParse(json['createdAt']) ?? DateTime.now(),
    );
  }
}

/// Weekly app usage entry — the most used app for a single day.
class WeeklyAppUsage {
  final int dayIndex; // 0=Mon, 6=Sun
  final String appName;
  final int minutes;
  final String category;
  final String iconPath;

  const WeeklyAppUsage({
    required this.dayIndex,
    required this.appName,
    required this.minutes,
    required this.category,
    required this.iconPath,
  });

  String get displayTime {
    if (minutes == 0) return '';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours > 0) return '${hours}h ${mins}m';
    return '${mins}m';
  }
}
