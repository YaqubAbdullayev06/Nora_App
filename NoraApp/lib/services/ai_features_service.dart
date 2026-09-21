/// AI Features Service — Smart Daily Plans, Sentiment Check-ins, Predictive Blocking.
///
/// Connects to the new AI endpoints for enhanced productivity features.

import 'package:flutter/foundation.dart';
import 'api_service.dart';

class AIFeaturesService {
  final ApiService _api;

  AIFeaturesService(this._api);

  // ─── Smart Daily Plans ───

  /// Generate an AI-optimized daily schedule.
  Future<DailyPlan> generateDailyPlan({
    required String ageGroup,
    List<String> goals = const [],
    double availableHours = 8.0,
    String energyPattern = 'normal',
    List<Map<String, dynamic>> existingCommitments = const [],
    Map<String, dynamic> preferences = const {},
  }) async {
    try {
      final response = await _api.postJson('/ai/daily-plan', {
        'age_group': ageGroup,
        'goals': goals,
        'available_hours': availableHours,
        'energy_pattern': energyPattern,
        'existing_commitments': existingCommitments,
        'preferences': preferences,
      });

      if (response['success'] == true) {
        return DailyPlan.fromJson(response);
      }
      return DailyPlan.fallback(availableHours);
    } catch (e) {
      debugPrint('Daily plan generation failed: $e');
      return DailyPlan.fallback(availableHours);
    }
  }

  // ─── Sentiment-Aware Check-ins ───

  /// Analyze user sentiment and get empathetic response.
  Future<SentimentResult> checkSentiment({
    required String message,
    required String ageGroup,
    Map<String, dynamic> context = const {},
  }) async {
    try {
      final response = await _api.postJson('/ai/sentiment-check', {
        'message': message,
        'age_group': ageGroup,
        'context': context,
      });

      if (response['success'] == true) {
        return SentimentResult.fromJson(response);
      }
      return SentimentResult.fallback();
    } catch (e) {
      debugPrint('Sentiment check failed: $e');
      return SentimentResult.fallback();
    }
  }

  // ─── Predictive App Blocking ───

  /// Get predictive blocking suggestions.
  Future<PredictiveResult> getPredictions({
    required String ageGroup,
    String currentTime = '',
    String dayOfWeek = '',
    Map<String, dynamic> recentUsage = const {},
    List<Map<String, dynamic>> installedApps = const [],
  }) async {
    try {
      final response = await _api.postJson('/ai/predictive-blocking', {
        'age_group': ageGroup,
        'current_time': currentTime,
        'day_of_week': dayOfWeek,
        'recent_usage': recentUsage,
        'installed_apps': installedApps,
      });

      if (response['success'] == true) {
        return PredictiveResult.fromJson(response);
      }
      return PredictiveResult.empty();
    } catch (e) {
      debugPrint('Predictive blocking failed: $e');
      return PredictiveResult.empty();
    }
  }
}

// ─── Data Models ───

class DailyPlan {
  final List<PlanBlock> plan;
  final String summary;
  final int totalFocusMinutes;
  final int totalBreakMinutes;
  final String tip;

  DailyPlan({
    required this.plan,
    required this.summary,
    required this.totalFocusMinutes,
    required this.totalBreakMinutes,
    required this.tip,
  });

  factory DailyPlan.fromJson(Map<String, dynamic> json) {
    final planList = (json['plan'] as List<dynamic>? ?? [])
        .map((b) => PlanBlock.fromJson(b as Map<String, dynamic>))
        .toList();
    return DailyPlan(
      plan: planList,
      summary: json['summary'] ?? '',
      totalFocusMinutes: json['total_focus_minutes'] ?? 0,
      totalBreakMinutes: json['total_break_minutes'] ?? 0,
      tip: json['tip'] ?? '',
    );
  }

  factory DailyPlan.fallback(double availableHours) {
    final blocks = <PlanBlock>[];
    final totalMinutes = (availableHours * 60).toInt();
    int elapsed = 0;
    int hour = 9;

    while (elapsed < totalMinutes - 25) {
      final focusDuration = (totalMinutes - elapsed - 5).clamp(15, 25);
      blocks.add(PlanBlock(
        time: '${hour.toString().padLeft(2, '0')}:${(elapsed % 60).toString().padLeft(2, '0')}',
        endTime: '${hour.toString().padLeft(2, '0')}:${((elapsed + focusDuration) % 60).toString().padLeft(2, '0')}',
        type: 'focus',
        title: 'Focus Session',
        description: 'Pomodoro block — $focusDuration minutes',
        energyLevel: elapsed < totalMinutes * 0.5 ? 'high' : 'medium',
      ));
      elapsed += focusDuration;

      if (elapsed < totalMinutes - 10) {
        blocks.add(PlanBlock(
          time: '${hour.toString().padLeft(2, '0')}:${(elapsed % 60).toString().padLeft(2, '0')}',
          endTime: '${hour.toString().padLeft(2, '0')}:${((elapsed + 5) % 60).toString().padLeft(2, '0')}',
          type: 'break',
          title: 'Short Break',
          description: 'Stretch and recharge',
          energyLevel: 'low',
        ));
        elapsed += 5;
      }
      if (elapsed % 60 < 25) hour++;
    }

    return DailyPlan(
      plan: blocks,
      summary: 'A productive day with balanced work and breaks.',
      totalFocusMinutes: (availableHours * 36).toInt(),
      totalBreakMinutes: (availableHours * 24).toInt(),
      tip: 'Start with your most important task when energy is highest.',
    );
  }
}

class PlanBlock {
  final String time;
  final String endTime;
  final String type;
  final String title;
  final String description;
  final String energyLevel;

  PlanBlock({
    required this.time,
    required this.endTime,
    required this.type,
    required this.title,
    required this.description,
    required this.energyLevel,
  });

  factory PlanBlock.fromJson(Map<String, dynamic> json) {
    return PlanBlock(
      time: json['time'] ?? '',
      endTime: json['end_time'] ?? '',
      type: json['type'] ?? 'focus',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      energyLevel: json['energy_level'] ?? 'medium',
    );
  }

  bool get isFocus => type == 'focus';
  bool get isBreak => type == 'break';
}

class SentimentResult {
  final String sentiment;
  final double confidence;
  final String response;
  final String suggestion;
  final int moodScore;

  SentimentResult({
    required this.sentiment,
    required this.confidence,
    required this.response,
    required this.suggestion,
    required this.moodScore,
  });

  factory SentimentResult.fromJson(Map<String, dynamic> json) {
    return SentimentResult(
      sentiment: json['sentiment'] ?? 'neutral',
      confidence: (json['confidence'] ?? 0.7).toDouble(),
      response: json['response'] ?? '',
      suggestion: json['suggestion'] ?? '',
      moodScore: json['mood_score'] ?? 5,
    );
  }

  factory SentimentResult.fallback() {
    return SentimentResult(
      sentiment: 'neutral',
      confidence: 0.5,
      response: 'Thanks for sharing. How can I help you today?',
      suggestion: 'Check your daily plan for what\'s next.',
      moodScore: 5,
    );
  }

  bool get isPositive => sentiment == 'positive' || sentiment == 'motivated';
  bool get isNegative => sentiment == 'negative' || sentiment == 'stressed';
}

class PredictiveResult {
  final List<Prediction> predictions;
  final List<ProactiveNudge> proactiveNudges;
  final List<SuggestedBlock> suggestedBlock;
  final String summary;

  PredictiveResult({
    required this.predictions,
    required this.proactiveNudges,
    required this.suggestedBlock,
    required this.summary,
  });

  factory PredictiveResult.fromJson(Map<String, dynamic> json) {
    return PredictiveResult(
      predictions: (json['predictions'] as List<dynamic>? ?? [])
          .map((p) => Prediction.fromJson(p as Map<String, dynamic>))
          .toList(),
      proactiveNudges: (json['proactive_nudges'] as List<dynamic>? ?? [])
          .map((n) => ProactiveNudge.fromJson(n as Map<String, dynamic>))
          .toList(),
      suggestedBlock: (json['suggested_block'] as List<dynamic>? ?? [])
          .map((b) => SuggestedBlock.fromJson(b as Map<String, dynamic>))
          .toList(),
      summary: json['summary'] ?? '',
    );
  }

  factory PredictiveResult.empty() {
    return PredictiveResult(
      predictions: [],
      proactiveNudges: [],
      suggestedBlock: [],
      summary: 'No predictions available.',
    );
  }

  int get highRiskCount => predictions.where((p) => p.riskLevel == 'high').length;
}

class Prediction {
  final String time;
  final String riskLevel;
  final String reason;
  final List<String> appsAtRisk;
  final String suggestion;

  Prediction({
    required this.time,
    required this.riskLevel,
    required this.reason,
    required this.appsAtRisk,
    required this.suggestion,
  });

  factory Prediction.fromJson(Map<String, dynamic> json) {
    return Prediction(
      time: json['time'] ?? '',
      riskLevel: json['risk_level'] ?? 'low',
      reason: json['reason'] ?? '',
      appsAtRisk: (json['apps_at_risk'] as List<dynamic>? ?? [])
          .map((a) => a.toString())
          .toList(),
      suggestion: json['suggestion'] ?? '',
    );
  }

  bool get isHighRisk => riskLevel == 'high';
  bool get isMediumRisk => riskLevel == 'medium';
}

class ProactiveNudge {
  final String triggerTime;
  final String message;
  final String action;

  ProactiveNudge({
    required this.triggerTime,
    required this.message,
    required this.action,
  });

  factory ProactiveNudge.fromJson(Map<String, dynamic> json) {
    return ProactiveNudge(
      triggerTime: json['trigger_time'] ?? '',
      message: json['message'] ?? '',
      action: json['action'] ?? '',
    );
  }
}

class SuggestedBlock {
  final String packageName;
  final String blockUntil;
  final String reason;

  SuggestedBlock({
    required this.packageName,
    required this.blockUntil,
    required this.reason,
  });

  factory SuggestedBlock.fromJson(Map<String, dynamic> json) {
    return SuggestedBlock(
      packageName: json['packageName'] ?? '',
      blockUntil: json['block_until'] ?? '',
      reason: json['reason'] ?? '',
    );
  }
}
