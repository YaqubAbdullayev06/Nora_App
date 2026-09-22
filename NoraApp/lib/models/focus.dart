/// Focus session model for tracking work sessions.
class FocusSession {
  final String id;
  final DateTime startTime;
  final DateTime? endTime;
  final int durationMinutes;
  final int pointsEarned;
  final bool completed;

  const FocusSession({
    required this.id,
    required this.startTime,
    this.endTime,
    required this.durationMinutes,
    required this.pointsEarned,
    required this.completed,
  });

  factory FocusSession.fromJson(Map<String, dynamic> json) {
    return FocusSession(
      id: json['id']?.toString() ?? '',
      startTime: DateTime.parse(
          json['started_at'] ?? json['startTime'] ?? DateTime.now().toIso8601String()),
      endTime: json['ended_at'] != null
          ? DateTime.parse(json['ended_at'])
          : json['endTime'] != null
              ? DateTime.parse(json['endTime'])
              : null,
      durationMinutes: json['duration_minutes'] ?? json['durationMinutes'] ?? 0,
      pointsEarned: json['points_earned'] ?? json['pointsEarned'] ?? 0,
      completed: json['completed'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'durationMinutes': durationMinutes,
      'pointsEarned': pointsEarned,
      'completed': completed,
    };
  }
}

/// AI recommendation model.
class AIRecommendation {
  final String id;
  final String title;
  final String description;
  final String type;
  final double confidence;

  const AIRecommendation({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.confidence,
  });

  factory AIRecommendation.fromJson(Map<String, dynamic> json) {
    return AIRecommendation(
      // Backend returns content_id (int); local/homegrown data uses id
      id: (json['id'] ?? json['content_id'] ?? '').toString(),
      title: json['title'] ?? '',
      // Backend returns reason (not description)
      description: json['description'] ?? json['reason'] ?? '',
      type: json['type'] ?? '',
      confidence: (json['confidence'] ?? json['confidence_score'] ?? 0)
          .toDouble(),
    );
  }
}

/// Focus score model.
class FocusScore {
  final int score;
  final int totalMinutes;
  final int sessions;

  const FocusScore({
    required this.score,
    required this.totalMinutes,
    required this.sessions,
  });

  factory FocusScore.fromJson(Map<String, dynamic> json) {
    return FocusScore(
      // Backend returns total_points; legacy/local data uses score
      score: json['score'] ?? json['total_points'] ?? 0,
      totalMinutes:
          json['totalMinutes'] ?? json['total_focus_minutes'] ?? 0,
      sessions: json['sessions'] ?? json['sessions_completed'] ?? 0,
    );
  }
}
