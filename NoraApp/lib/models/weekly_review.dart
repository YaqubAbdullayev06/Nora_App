import '../core/enums/age_group.dart';

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
      id: json['id'] ?? '',
      question: json['question'] ?? '',
      answer: json['answer'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
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
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      targetMinutes: json['targetMinutes'] ?? 0,
      completedMinutes: json['completedMinutes'] ?? 0,
      isCompleted: json['isCompleted'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
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
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

    switch (ageGroup) {
      case AgeGroup.baby:
        return [
          WeeklyGoal(id: 'goal_1', title: 'Learning Time', targetMinutes: 15, createdAt: startOfWeek),
          WeeklyGoal(id: 'goal_2', title: 'Play & Explore', targetMinutes: 20, createdAt: startOfWeek),
        ];
      case AgeGroup.child:
        return [
          WeeklyGoal(id: 'goal_1', title: 'Fun Learning', targetMinutes: 20, createdAt: startOfWeek),
          WeeklyGoal(id: 'goal_2', title: 'Creative Play', targetMinutes: 25, createdAt: startOfWeek),
        ];
      case AgeGroup.kid:
        return [
          WeeklyGoal(id: 'goal_1', title: 'Study Focus', targetMinutes: 60, createdAt: startOfWeek),
          WeeklyGoal(id: 'goal_2', title: 'Reading Time', targetMinutes: 30, createdAt: startOfWeek),
          WeeklyGoal(id: 'goal_3', title: 'Creative Activities', targetMinutes: 20, createdAt: startOfWeek),
        ];
      case AgeGroup.teen:
        return [
          WeeklyGoal(id: 'goal_1', title: 'Deep Study Sessions', targetMinutes: 120, createdAt: startOfWeek),
          WeeklyGoal(id: 'goal_2', title: 'Skill Practice', targetMinutes: 60, createdAt: startOfWeek),
          WeeklyGoal(id: 'goal_3', title: 'Mindfulness', targetMinutes: 30, createdAt: startOfWeek),
        ];
      case AgeGroup.adult:
        return [
          WeeklyGoal(id: 'goal_1', title: 'Deep Work Hours', targetMinutes: 300, createdAt: startOfWeek),
          WeeklyGoal(id: 'goal_2', title: 'Learning & Growth', targetMinutes: 120, createdAt: startOfWeek),
          WeeklyGoal(id: 'goal_3', title: 'Exercise & Wellness', targetMinutes: 150, createdAt: startOfWeek),
          WeeklyGoal(id: 'goal_4', title: 'Side Projects', targetMinutes: 60, createdAt: startOfWeek),
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
    return WeeklyReview(
      id: json['id'] ?? '',
      weekStart: DateTime.parse(json['weekStart'] ?? DateTime.now().toIso8601String()),
      weekEnd: DateTime.parse(json['weekEnd'] ?? DateTime.now().toIso8601String()),
      mood: json['mood'] != null ? WeeklyMood.values[json['mood']] : null,
      reflections: (json['reflections'] as List?)
              ?.map((r) => WeeklyReflection.fromJson(r))
              .toList() ??
          [],
      goals: (json['goals'] as List?)
              ?.map((g) => WeeklyGoal.fromJson(g))
              .toList() ??
          [],
      totalFocusMinutes: json['totalFocusMinutes'] ?? 0,
      totalSessions: json['totalSessions'] ?? 0,
      totalPointsEarned: json['totalPointsEarned'] ?? 0,
      streakDays: json['streakDays'] ?? 0,
      aiInsight: json['aiInsight'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
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
