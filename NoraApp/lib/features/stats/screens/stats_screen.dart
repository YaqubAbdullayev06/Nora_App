import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/design_tokens.dart';
import '../../../core/enums/age_group.dart';
import '../../../core/theme/persona_theme.dart';
import '../../../providers/persona_provider.dart';
import '../../../providers/focus_provider.dart';
import '../../../widgets/nora_components.dart';
import '../../breathing/providers/breathing_provider.dart';

/// Stats Screen — age-adaptive analytics.
/// Baby: simple colors and shapes, smiley faces
/// Kid: game-like progress bars, achievement badges
/// Teen: charts, streaks, detailed stats
/// Adult: detailed analytics, productivity metrics
class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<PersonaProvider, FocusProvider>(
      builder: (context, personaProvider, focusProvider, _) {
        final persona = personaProvider.persona;

        return Scaffold(
          backgroundColor: DesignTokens.background,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(DesignTokens.spacing20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(persona),
                  const SizedBox(height: DesignTokens.spacing24),
                  _buildWeeklyChart(focusProvider, persona),
                  const SizedBox(height: DesignTokens.spacing24),
                  _buildDetailedStats(context, focusProvider, persona),
                  const SizedBox(height: DesignTokens.spacing24),
                  _buildBreathingStats(context, persona),
                  const SizedBox(height: DesignTokens.spacing24),
                  _buildAchievements(focusProvider, persona),
                  if (persona.ageGroup != AgeGroup.baby) ...[
                    const SizedBox(height: DesignTokens.spacing24),
                    _buildInsights(focusProvider, persona),
                  ],
                  const SizedBox(height: DesignTokens.spacing24),
                  _buildScreenTimeButton(context, persona),
                  const SizedBox(height: DesignTokens.spacing24),
                  _buildWeeklyReviewButton(context, persona),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(PersonaTheme persona) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getStatsTitle(persona.ageGroup),
                style: TextStyle(
                  color: DesignTokens.textPrimary,
                  fontSize: DesignTokens.fontSizeH2,
                  fontWeight: DesignTokens.fontWeightBold,
                  fontFamily: DesignTokens.fontFamilyDisplay,
                ),
              ),
              Text(
                _getStatsSubtitle(persona.ageGroup),
                style: TextStyle(
                  color: DesignTokens.textMuted,
                  fontSize: DesignTokens.fontSizeBodySmall,
                  fontFamily: DesignTokens.fontFamilyPrimary,
                ),
              ),
            ],
          ),
        ),
        NoraMascot(size: 48, showGlow: false),
      ],
    );
  }

  Widget _buildWeeklyChart(FocusProvider provider, PersonaTheme persona) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final appUsage = provider.weeklyAppUsage;
    final maxMinutes = appUsage.map((e) => e.minutes).reduce((a, b) => a > b ? a : b).toDouble();

    return NoraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: _getChartTitle(persona.ageGroup),
            icon: Icons.bar_chart_rounded,
            iconColor: persona.primary,
          ),
          const SizedBox(height: DesignTokens.spacing16),
          SizedBox(
            height: 180,
            child: maxMinutes == 0
                ? Center(
                    child: Text(
                      'No app usage data this week yet',
                      style: TextStyle(
                        color: DesignTokens.textMuted,
                        fontSize: DesignTokens.fontSizeCaption,
                        fontFamily: DesignTokens.fontFamilyPrimary,
                      ),
                    ),
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(7, (index) {
                      final usage = appUsage[index];
                      final height = usage.minutes > 0
                          ? (usage.minutes / maxMinutes) * 100
                          : 0.0;
                      final isToday = index == DateTime.now().weekday - 1;
                      final hasData = usage.minutes > 0;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              // App icon + name + time
                              if (hasData) ...[
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: SvgPicture.asset(
                                    usage.iconPath,
                                    fit: BoxFit.contain,
                                    placeholderBuilder: (context) => Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: DesignTokens.border,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  usage.appName,
                                  style: TextStyle(
                                    color: isToday ? persona.primary : DesignTokens.textMuted,
                                    fontSize: DesignTokens.fontSizeNano,
                                    fontWeight: isToday ? DesignTokens.fontWeightSemiBold : DesignTokens.fontWeightRegular,
                                    fontFamily: DesignTokens.fontFamilyPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                                Text(
                                  usage.displayTime,
                                  style: TextStyle(
                                    color: isToday ? persona.primary : DesignTokens.textMuted,
                                    fontSize: DesignTokens.fontSizeMicro,
                                    fontWeight: DesignTokens.fontWeightBold,
                                    fontFamily: DesignTokens.fontFamilyPrimary,
                                  ),
                                ),
                              ] else ...[
                                const SizedBox(height: 32),
                              ],
                              const SizedBox(height: DesignTokens.spacing4),
                              // Bar
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                height: height,
                                decoration: BoxDecoration(
                                  gradient: hasData
                                      ? LinearGradient(
                                          colors: [
                                            persona.primary,
                                            persona.primary.withValues(alpha: 0.6),
                                          ],
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                        )
                                      : null,
                                  color: hasData ? null : DesignTokens.border.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(DesignTokens.radius4),
                                ),
                              ),
                              const SizedBox(height: DesignTokens.spacing4),
                              // Day label
                              Text(
                                days[index],
                                style: TextStyle(
                                  color: isToday ? persona.primary : DesignTokens.textMuted,
                                  fontSize: DesignTokens.fontSizeTiny,
                                  fontWeight: isToday ? DesignTokens.fontWeightSemiBold : DesignTokens.fontWeightRegular,
                                  fontFamily: DesignTokens.fontFamilyPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedStats(BuildContext context, FocusProvider provider, PersonaTheme persona) {
    final stats = _getDetailedStats(provider, persona);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: _getDetailedTitle(persona.ageGroup),
          icon: Icons.analytics_rounded,
          iconColor: DesignTokens.accent,
        ),
        const SizedBox(height: DesignTokens.spacing12),
        Wrap(
          spacing: DesignTokens.spacing12,
          runSpacing: DesignTokens.spacing12,
          children: stats.map((stat) {
            return SizedBox(
              width: (MediaQuery.of(context).size.width - 52) / 2,
              child: StatsCard(
                label: stat['label']!,
                value: stat['value']!,
                icon: _getStatIcon(stat['icon']!),
                color: _getStatColor(stat['color']!),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBreathingStats(BuildContext context, PersonaTheme persona) {
    return Consumer<BreathingProvider>(
      builder: (context, breathing, _) {
        final stats = breathing.stats;
        if (stats.totalSessions == 0) {
          return const SizedBox.shrink();
        }
        return NoraCard(
          backgroundColor: persona.primary.withValues(alpha: 0.06),
          border: Border.all(
            color: persona.primary.withValues(alpha: 0.15),
            width: 1,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: 'Breathing Exercises',
                icon: Icons.air_rounded,
                iconColor: persona.primary,
              ),
              const SizedBox(height: DesignTokens.spacing12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildBreathStatItem(
                    '${stats.totalSessions}',
                    'Sessions',
                    Icons.repeat_rounded,
                    persona.primary,
                  ),
                  _buildBreathStatItem(
                    '${stats.totalMinutes}',
                    'Minutes',
                    Icons.schedule_rounded,
                    persona.secondary,
                  ),
                  _buildBreathStatItem(
                    '${stats.currentStreak}',
                    'Streak',
                    Icons.local_fire_department_rounded,
                    DesignTokens.warning,
                  ),
                  _buildBreathStatItem(
                    '${stats.pointsEarned}',
                    'Points',
                    Icons.star_rounded,
                    DesignTokens.success,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBreathStatItem(
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: DesignTokens.textPrimary,
            fontSize: DesignTokens.fontSizeBody,
            fontWeight: DesignTokens.fontWeightBold,
            fontFamily: DesignTokens.fontFamilyPrimary,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: DesignTokens.textMuted,
            fontSize: DesignTokens.fontSizeTiny,
            fontFamily: DesignTokens.fontFamilyPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildAchievements(FocusProvider provider, PersonaTheme persona) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: _getAchievementsTitle(persona.ageGroup),
          icon: Icons.emoji_events_rounded,
          iconColor: DesignTokens.warning,
        ),
        const SizedBox(height: DesignTokens.spacing12),
        SizedBox(
          height: 80,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: provider.achievements.length,
            separatorBuilder: (_, __) => const SizedBox(width: DesignTokens.spacing12),
            itemBuilder: (context, index) {
              final achievement = provider.achievements[index];
              return _buildAchievementBadge(achievement, persona);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementBadge(String achievement, PersonaTheme persona) {
    final assetPath = _getAchievementAsset(achievement);
    return Container(
      width: 80,
      decoration: BoxDecoration(
        color: DesignTokens.surface,
        borderRadius: BorderRadius.circular(DesignTokens.radius16),
        border: Border.all(color: DesignTokens.border, width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: assetPath != null
                ? SvgPicture.asset(
                    assetPath,
                    fit: BoxFit.contain,
                  )
                : Center(
                    child: Icon(
                      _getAchievementIcon(achievement),
                      size: 28,
                      color: DesignTokens.accent,
                    ),
                  ),
          ),
          const SizedBox(height: DesignTokens.spacing4),
            Text(
              achievement,
              style: TextStyle(
                color: DesignTokens.textMuted,
                fontSize: DesignTokens.fontSizeTiny,
                fontFamily: DesignTokens.fontFamilyPrimary,
              ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildInsights(FocusProvider provider, PersonaTheme persona) {
    final insights = _getInsightsForAgeGroup(persona.ageGroup);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: _getInsightsTitle(persona.ageGroup),
          icon: Icons.lightbulb_rounded,
          iconColor: DesignTokens.success,
        ),
        const SizedBox(height: DesignTokens.spacing12),
        ...insights.map((insight) => Padding(
          padding: const EdgeInsets.only(bottom: DesignTokens.spacing8),
          child: NoraCard(
            child: Row(
              children: [
                Icon(insight['icon'] as IconData, size: 24, color: DesignTokens.accent),
                const SizedBox(width: DesignTokens.spacing12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        insight['title']!,
                        style: TextStyle(
                          color: DesignTokens.textPrimary,
                          fontSize: DesignTokens.fontSizeBodySmall,
                          fontWeight: DesignTokens.fontWeightSemiBold,
                          fontFamily: DesignTokens.fontFamilyPrimary,
                        ),
                      ),
                      Text(
                        insight['description']!,
                        style: TextStyle(
                          color: DesignTokens.textMuted,
                          fontSize: DesignTokens.fontSizeCaption,
                          fontFamily: DesignTokens.fontFamilyPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildWeeklyReviewButton(BuildContext context, PersonaTheme persona) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/weekly-review'),
      child: NoraCard(
        backgroundColor: DesignTokens.accentSecondary.withValues(alpha: 0.1),
        border: Border.all(
            color: DesignTokens.accentSecondary.withValues(alpha: 0.3),
            width: 1),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    DesignTokens.accentSecondary,
                    DesignTokens.accent
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.calendar_month,
                  color: Colors.white, size: 24),
            ),
            const SizedBox(width: DesignTokens.spacing16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Weekly Review',
                    style: TextStyle(
                      color: DesignTokens.textPrimary,
                      fontSize: DesignTokens.fontSizeBody,
                      fontWeight: DesignTokens.fontWeightSemiBold,
                      fontFamily: DesignTokens.fontFamilyPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _getWeeklyReviewSubtitle(persona.ageGroup),
                    style: TextStyle(
                      color: DesignTokens.textMuted,
                      fontSize: DesignTokens.fontSizeCaption,
                      fontFamily: DesignTokens.fontFamilyPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                color: DesignTokens.textMuted, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildScreenTimeButton(BuildContext context, PersonaTheme persona) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/screen-time'),
      child: NoraCard(
        backgroundColor: DesignTokens.success.withValues(alpha: 0.1),
        border: Border.all(
            color: DesignTokens.success.withValues(alpha: 0.3),
            width: 1),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: DesignTokens.success,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.screen_lock_portrait_rounded,
                  color: Colors.white, size: 24),
            ),
            const SizedBox(width: DesignTokens.spacing16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Screen Time',
                    style: TextStyle(
                      color: DesignTokens.textPrimary,
                      fontSize: DesignTokens.fontSizeBody,
                      fontWeight: DesignTokens.fontWeightSemiBold,
                      fontFamily: DesignTokens.fontFamilyPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _getScreenTimeSubtitle(persona.ageGroup),
                    style: TextStyle(
                      color: DesignTokens.textMuted,
                      fontSize: DesignTokens.fontSizeCaption,
                      fontFamily: DesignTokens.fontFamilyPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                color: DesignTokens.textMuted, size: 16),
          ],
        ),
      ),
    );
  }

  String _getScreenTimeSubtitle(AgeGroup group) {
    switch (group) {
      case AgeGroup.baby:
        return 'See how long you\'ve been playing';
      case AgeGroup.child:
        return 'Check your device time';
      case AgeGroup.kid:
        return 'Track your daily screen usage';
      case AgeGroup.teen:
        return 'Monitor your screen habits';
      case AgeGroup.adult:
        return 'Get detailed usage insights';
    }
  }

  String _getWeeklyReviewSubtitle(AgeGroup group) {
    switch (group) {
      case AgeGroup.baby:
        return 'See all the fun things you did!';
      case AgeGroup.child:
        return 'See all the fun things you did!';
      case AgeGroup.kid:
        return 'Check out your weekly progress';
      case AgeGroup.teen:
        return 'Reflect on your week and set goals';
      case AgeGroup.adult:
        return 'Reflect, plan, and track your progress';
    }
  }

  // ─── Age-specific helpers ───

  String _getStatsTitle(AgeGroup group) {
    switch (group) {
      case AgeGroup.baby: return 'My Progress';
      case AgeGroup.child: return 'My Progress';
      case AgeGroup.kid: return 'Your Stats';
      case AgeGroup.teen: return 'Analytics';
      case AgeGroup.adult: return 'Statistics';
    }
  }

  String _getStatsSubtitle(AgeGroup group) {
    switch (group) {
      case AgeGroup.baby: return 'Look how much you\'ve done!';
      case AgeGroup.child: return 'Look how much you\'ve done!';
      case AgeGroup.kid: return 'Track your adventure!';
      case AgeGroup.teen: return 'Your learning journey';
      case AgeGroup.adult: return 'Your productivity overview';
    }
  }

  String _getChartTitle(AgeGroup group) {
    switch (group) {
      case AgeGroup.baby: return 'This Week';
      case AgeGroup.child: return 'This Week';
      case AgeGroup.kid: return 'Weekly Quest';
      case AgeGroup.teen: return 'Weekly Focus';
      case AgeGroup.adult: return 'Weekly Overview';
    }
  }

  String _getDetailedTitle(AgeGroup group) {
    switch (group) {
      case AgeGroup.baby: return 'Fun Facts';
      case AgeGroup.child: return 'Fun Facts';
      case AgeGroup.kid: return 'Stats Breakdown';
      case AgeGroup.teen: return 'Detailed Stats';
      case AgeGroup.adult: return 'Detailed Metrics';
    }
  }

  String _getAchievementsTitle(AgeGroup group) {
    switch (group) {
      case AgeGroup.baby: return 'My Badges';
      case AgeGroup.child: return 'My Badges';
      case AgeGroup.kid: return 'Achievements';
      case AgeGroup.teen: return 'Badges Earned';
      case AgeGroup.adult: return 'Achievements';
    }
  }

  String _getInsightsTitle(AgeGroup group) {
    switch (group) {
      case AgeGroup.kid: return 'Nora\'s Tips';
      case AgeGroup.teen: return 'Insights';
      case AgeGroup.adult: return 'AI Insights';
      default: return 'Tips';
    }
  }

  List<Map<String, String>> _getDetailedStats(FocusProvider provider, PersonaTheme persona) {
    return [
      {'label': 'Total Focus', 'value': '${provider.totalFocusMinutes}m', 'icon': 'schedule', 'color': 'primary'},
      {'label': 'Sessions', 'value': '${provider.sessionsCompleted}', 'icon': 'check_circle', 'color': 'success'},
      {'label': 'Streak', 'value': '${provider.streakDays} days', 'icon': 'local_fire_department', 'color': 'warning'},
      {'label': _getScoreLabel(persona.ageGroup), 'value': '${provider.focusScore}', 'icon': 'star', 'color': 'secondary'},
    ];
  }

  String _getScoreLabel(AgeGroup group) {
    switch (group) {
      case AgeGroup.baby: return 'Stars';
      case AgeGroup.child: return 'Stars';
      case AgeGroup.kid: return 'Points';
      case AgeGroup.teen: return 'XP';
      case AgeGroup.adult: return 'Score';
    }
  }

  IconData _getAchievementIcon(String achievement) {
    switch (achievement) {
      case 'First Focus': return Icons.star_rounded;
      case '3-Day Streak': return Icons.local_fire_department_rounded;
      case 'Early Bird': return Icons.wb_sunny_rounded;
      default: return Icons.emoji_events_rounded;
    }
  }

  String? _getAchievementAsset(String achievement) {
    switch (achievement) {
      case 'First Focus': return 'assets/images/achievements/first_focus.svg';
      case '3-Day Streak': return 'assets/images/achievements/streak_3.svg';
      case 'Early Bird': return 'assets/images/achievements/early_bird.svg';
      default: return null;
    }
  }

  IconData _getStatIcon(String icon) {
    switch (icon) {
      case 'schedule': return Icons.schedule_rounded;
      case 'check_circle': return Icons.check_circle_rounded;
      case 'local_fire_department': return Icons.local_fire_department_rounded;
      case 'star': return Icons.star_rounded;
      default: return Icons.analytics_rounded;
    }
  }

  Color _getStatColor(String color) {
    switch (color) {
      case 'primary': return DesignTokens.accent;
      case 'success': return DesignTokens.success;
      case 'warning': return DesignTokens.warning;
      case 'secondary': return DesignTokens.accentSecondary;
      default: return DesignTokens.accent;
    }
  }

  List<Map<String, dynamic>> _getInsightsForAgeGroup(AgeGroup group) {
    switch (group) {
      case AgeGroup.kid:
        return [
          {'icon': Icons.gps_fixed_rounded, 'title': 'Consistency is key', 'description': 'You focused 3 days in a row!'},
          {'icon': Icons.schedule_rounded, 'title': 'Best time', 'description': 'You focus best in the morning'},
          {'icon': Icons.trending_up_rounded, 'title': 'Improving!', 'description': '15% more focus than last week'},
        ];
      case AgeGroup.teen:
        return [
          {'icon': Icons.analytics_rounded, 'title': 'Peak Performance', 'description': 'Your best focus sessions are 25-35 min'},
          {'icon': Icons.sync_rounded, 'title': 'Pattern Detected', 'description': 'You focus best on weekdays'},
          {'icon': Icons.gps_fixed_rounded, 'title': 'Recommendation', 'description': 'Try active recall for better retention'},
        ];
      case AgeGroup.adult:
        return [
          {'icon': Icons.psychology_rounded, 'title': 'Deep Work', 'description': '45% of sessions in deep work mode'},
          {'icon': Icons.trending_up_rounded, 'title': 'Trend', 'description': 'Focus time up 20% this month'},
          {'icon': Icons.gps_fixed_rounded, 'title': 'Suggestion', 'description': 'Consider morning sessions for peak performance'},
        ];
      default:
        return [];
    }
  }
}
