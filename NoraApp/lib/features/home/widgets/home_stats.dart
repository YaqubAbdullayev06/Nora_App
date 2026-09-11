import 'package:flutter/material.dart';
import '../../../core/constants/design_tokens.dart';
import '../../../core/enums/age_group.dart';
import '../../../providers/app_provider.dart';
import '../../../widgets/nora_components.dart';

/// Horizontal scrollable stats cards — score, streak, focus time.
class HomeStats extends StatelessWidget {
  final AppProvider provider;

  const HomeStats({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final persona = provider.persona;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: "Today",
          icon: Icons.analytics_rounded,
          iconColor: DesignTokens.accent,
        ),
        const SizedBox(height: DesignTokens.spacing12),
        SizedBox(
          height: 120,
          child: ListView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            children: [
              SizedBox(
                width: 140,
                child: StatCardHorizontal(
                  label: _getScoreLabel(persona.ageGroup),
                  value: '${provider.focusScore}',
                  iconAsset: 'assets/images/icons/star.svg',
                  color: DesignTokens.accent,
                ),
              ),
              const SizedBox(width: DesignTokens.spacing12),
              SizedBox(
                width: 140,
                child: StatCardHorizontal(
                  label: _getStreakLabel(persona.ageGroup),
                  value: '${provider.streakDays}',
                  iconAsset: 'assets/images/icons/fire.svg',
                  color: DesignTokens.warning,
                ),
              ),
              const SizedBox(width: DesignTokens.spacing12),
              SizedBox(
                width: 140,
                child: StatCardHorizontal(
                  label: _getTimeLabel(persona.ageGroup),
                  value: '${provider.totalFocusMinutes}m',
                  iconAsset: 'assets/images/icons/target.svg',
                  color: DesignTokens.accentSecondary,
                ),
              ),
              const SizedBox(width: DesignTokens.spacing12),
              SizedBox(
                width: 140,
                child: StatCardHorizontal(
                  label: _getSessionsLabel(persona.ageGroup),
                  value: '${provider.sessionsCompleted}',
                  iconAsset: 'assets/images/icons/circle-check-big.svg',
                  color: DesignTokens.success,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getScoreLabel(AgeGroup group) {
    switch (group) {
      case AgeGroup.baby:
        return 'Stars';
      case AgeGroup.kid:
        return 'Points';
      case AgeGroup.teen:
        return 'XP';
      case AgeGroup.adult:
        return 'Score';
    }
  }

  String _getStreakLabel(AgeGroup group) {
    switch (group) {
      case AgeGroup.baby:
        return 'Days';
      case AgeGroup.kid:
        return 'Streak';
      case AgeGroup.teen:
        return 'Streak';
      case AgeGroup.adult:
        return 'Streak';
    }
  }

  String _getTimeLabel(AgeGroup group) {
    switch (group) {
      case AgeGroup.baby:
        return 'Play Time';
      case AgeGroup.kid:
        return 'Focus Time';
      case AgeGroup.teen:
        return 'Study Time';
      case AgeGroup.adult:
        return 'Deep Work';
    }
  }

  String _getSessionsLabel(AgeGroup group) {
    switch (group) {
      case AgeGroup.baby:
        return 'Plays';
      case AgeGroup.kid:
        return 'Quests';
      case AgeGroup.teen:
        return 'Sessions';
      case AgeGroup.adult:
        return 'Sessions';
    }
  }
}
