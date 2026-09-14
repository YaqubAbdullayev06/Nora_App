import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/design_tokens.dart';
import '../../../core/enums/age_group.dart';
import '../../../models/models.dart';
import '../../../providers/focus_provider.dart';
import '../../../widgets/nora_components.dart';

/// Focus History Screen — detailed session history, time-of-day analysis,
/// and trend charts for teen and adult age groups.
class FocusHistoryScreen extends StatelessWidget {
  const FocusHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.background,
      body: SafeArea(
        child: Consumer<FocusProvider>(
          builder: (context, focus, _) {
            return CustomScrollView(
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(DesignTokens.spacing20),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: DesignTokens.surface,
                              borderRadius: BorderRadius.circular(DesignTokens.radius12),
                              border: Border.all(color: DesignTokens.border),
                            ),
                            child: Icon(
                              Icons.arrow_back_ios_rounded,
                              color: DesignTokens.textPrimary,
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: DesignTokens.spacing12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Focus History',
                                style: TextStyle(
                                  color: DesignTokens.textPrimary,
                                  fontSize: DesignTokens.fontSizeH2,
                                  fontWeight: DesignTokens.fontWeightBold,
                                  fontFamily: DesignTokens.fontFamilyDisplay,
                                ),
                              ),
                              Text(
                                '${focus.sessionsCompleted} sessions completed',
                                style: TextStyle(
                                  color: DesignTokens.textMuted,
                                  fontSize: DesignTokens.fontSizeBodySmall,
                                  fontFamily: DesignTokens.fontFamilyPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Summary cards
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spacing20),
                    child: _buildSummaryCards(focus),
                  ),
                ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: DesignTokens.spacing24),
                ),

                // Best Time of Day
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spacing20),
                    child: _buildTimeOfDayAnalysis(focus),
                  ),
                ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: DesignTokens.spacing24),
                ),

                // Weekly Trend
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spacing20),
                    child: _buildWeeklyTrend(focus),
                  ),
                ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: DesignTokens.spacing24),
                ),

                // Session Duration Distribution
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spacing20),
                    child: _buildDurationDistribution(focus),
                  ),
                ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: DesignTokens.spacing24),
                ),

                // Recent Sessions List
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spacing20),
                    child: SectionHeader(
                      title: 'Recent Sessions',
                      icon: Icons.history_rounded,
                      iconColor: DesignTokens.accent,
                    ),
                  ),
                ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: DesignTokens.spacing12),
                ),

                if (focus.sessions.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spacing20),
                      child: NoraCard(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(DesignTokens.spacing32),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.timer_off_rounded,
                                  size: 48,
                                  color: DesignTokens.textMuted.withValues(alpha: 0.4),
                                ),
                                const SizedBox(height: DesignTokens.spacing12),
                                Text(
                                  'No sessions yet',
                                  style: TextStyle(
                                    color: DesignTokens.textMuted,
                                    fontSize: DesignTokens.fontSizeBody,
                                    fontFamily: DesignTokens.fontFamilyPrimary,
                                  ),
                                ),
                                const SizedBox(height: DesignTokens.spacing4),
                                Text(
                                  'Start a focus session to see your history here',
                                  style: TextStyle(
                                    color: DesignTokens.textMuted.withValues(alpha: 0.6),
                                    fontSize: DesignTokens.fontSizeCaption,
                                    fontFamily: DesignTokens.fontFamilyPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spacing20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final sortedSessions = List<FocusSession>.from(focus.sessions)
                            ..sort((a, b) => b.startTime.compareTo(a.startTime));
                          if (index >= sortedSessions.length) return null;
                          final session = sortedSessions[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: DesignTokens.spacing8),
                            child: _buildSessionCard(session, focus),
                          );
                        },
                        childCount: focus.sessions.length.clamp(0, 20),
                      ),
                    ),
                  ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: DesignTokens.spacing40),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummaryCards(FocusProvider focus) {
    final avgDuration = focus.sessionsCompleted > 0
        ? (focus.totalFocusMinutes / focus.sessionsCompleted).round()
        : 0;

    final bestStreak = focus.computedStreakDays;
    final totalHours = (focus.totalFocusMinutes / 60).toStringAsFixed(1);

    return Row(
      children: [
        Expanded(
          child: _buildMiniStat(
            '$totalHours',
            'Total Hours',
            Icons.access_time_rounded,
            DesignTokens.accent,
          ),
        ),
        const SizedBox(width: DesignTokens.spacing12),
        Expanded(
          child: _buildMiniStat(
            '$avgDuration',
            'Avg Minutes',
            Icons.trending_up_rounded,
            DesignTokens.success,
          ),
        ),
        const SizedBox(width: DesignTokens.spacing12),
        Expanded(
          child: _buildMiniStat(
            '$bestStreak',
            'Best Streak',
            Icons.local_fire_department_rounded,
            DesignTokens.warning,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniStat(String value, String label, IconData icon, Color color) {
    return NoraCard(
      backgroundColor: color.withValues(alpha: 0.06),
      border: Border.all(color: color.withValues(alpha: 0.15)),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: DesignTokens.spacing8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: DesignTokens.fontWeightBold,
              fontFamily: DesignTokens.fontFamilyDisplay,
            ),
          ),
          const SizedBox(height: DesignTokens.spacing2),
          Text(
            label,
            style: TextStyle(
              color: DesignTokens.textMuted,
              fontSize: 10,
              fontFamily: DesignTokens.fontFamilyPrimary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTimeOfDayAnalysis(FocusProvider focus) {
    // Compute session counts by hour of day
    final hourCounts = List.filled(24, 0);
    final hourMinutes = List.filled(24, 0);
    for (final s in focus.sessions.where((s) => s.completed)) {
      final h = s.startTime.hour;
      hourCounts[h]++;
      hourMinutes[h] += s.durationMinutes;
    }

    // Find peak period
    final morningMinutes = hourMinutes.sublist(6, 12).fold(0, (a, b) => a + b);
    final afternoonMinutes = hourMinutes.sublist(12, 18).fold(0, (a, b) => a + b);
    final eveningMinutes = hourMinutes.sublist(18, 24).fold(0, (a, b) => a + b);
    final nightMinutes = hourMinutes.sublist(0, 6).fold(0, (a, b) => a + b);

    final maxPeriod = [morningMinutes, afternoonMinutes, eveningMinutes, nightMinutes]
        .reduce((a, b) => a > b ? a : b);

    String peakLabel = 'No data';
    if (maxPeriod > 0) {
      if (morningMinutes == maxPeriod) peakLabel = 'Morning (6am-12pm)';
      else if (afternoonMinutes == maxPeriod) peakLabel = 'Afternoon (12pm-6pm)';
      else if (eveningMinutes == maxPeriod) peakLabel = 'Evening (6pm-12am)';
      else peakLabel = 'Night (12am-6am)';
    }

    return NoraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Best Time of Day',
            icon: Icons.wb_sunny_rounded,
            iconColor: DesignTokens.warning,
          ),
          const SizedBox(height: DesignTokens.spacing12),
          // Period bars
          _buildPeriodBar('Morning', '6am-12pm', morningMinutes, maxPeriod, DesignTokens.warning),
          const SizedBox(height: DesignTokens.spacing8),
          _buildPeriodBar('Afternoon', '12pm-6pm', afternoonMinutes, maxPeriod, DesignTokens.accent),
          const SizedBox(height: DesignTokens.spacing8),
          _buildPeriodBar('Evening', '6pm-12am', eveningMinutes, maxPeriod, DesignTokens.accentSecondary),
          const SizedBox(height: DesignTokens.spacing8),
          _buildPeriodBar('Night', '12am-6am', nightMinutes, maxPeriod, DesignTokens.textMuted),
          const SizedBox(height: DesignTokens.spacing12),
          // Peak indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: DesignTokens.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(DesignTokens.radius8),
              border: Border.all(color: DesignTokens.success.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.star_rounded, color: DesignTokens.success, size: 16),
                const SizedBox(width: DesignTokens.spacing8),
                Expanded(
                  child: Text(
                    maxPeriod > 0 ? 'Peak focus: $peakLabel' : 'Complete sessions to see your best time',
                    style: TextStyle(
                      color: DesignTokens.success,
                      fontSize: DesignTokens.fontSizeCaption,
                      fontWeight: DesignTokens.fontWeightMedium,
                      fontFamily: DesignTokens.fontFamilyPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodBar(String label, String timeRange, int minutes, int maxMinutes, Color color) {
    final fraction = maxMinutes > 0 ? minutes / maxMinutes : 0.0;
    return Row(
      children: [
        SizedBox(
          width: 70,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: DesignTokens.textPrimary,
                  fontSize: DesignTokens.fontSizeCaption,
                  fontWeight: DesignTokens.fontWeightMedium,
                  fontFamily: DesignTokens.fontFamilyPrimary,
                ),
              ),
              Text(
                timeRange,
                style: TextStyle(
                  color: DesignTokens.textMuted,
                  fontSize: 10,
                  fontFamily: DesignTokens.fontFamilyPrimary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: DesignTokens.spacing8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 8,
              backgroundColor: DesignTokens.border.withValues(alpha: 0.3),
              valueColor: AlwaysStoppedAnimation<Color>(
                fraction > 0 ? color : DesignTokens.border,
              ),
            ),
          ),
        ),
        const SizedBox(width: DesignTokens.spacing8),
        SizedBox(
          width: 45,
          child: Text(
            '${minutes}m',
            style: TextStyle(
              color: fraction > 0 ? color : DesignTokens.textMuted,
              fontSize: DesignTokens.fontSizeCaption,
              fontWeight: DesignTokens.fontWeightBold,
              fontFamily: DesignTokens.fontFamilyPrimary,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyTrend(FocusProvider focus) {
    final weeklyMinutes = focus.weeklyFocusMinutes;
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final maxMinutes = weeklyMinutes.reduce((a, b) => a > b ? a : b).toDouble();

    return NoraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Weekly Trend',
            icon: Icons.show_chart_rounded,
            iconColor: DesignTokens.accent,
          ),
          const SizedBox(height: DesignTokens.spacing16),
          SizedBox(
            height: 140,
            child: maxMinutes == 0
                ? Center(
                    child: Text(
                      'No data this week',
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
                      final minutes = weeklyMinutes[index];
                      final height = minutes > 0 ? (minutes / maxMinutes) * 100 : 0.0;
                      final isToday = index == DateTime.now().weekday - 1;
                      final hasData = minutes > 0;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (hasData)
                                Text(
                                  '${minutes}m',
                                  style: TextStyle(
                                    color: isToday ? DesignTokens.accent : DesignTokens.textMuted,
                                    fontSize: 9,
                                    fontWeight: DesignTokens.fontWeightBold,
                                    fontFamily: DesignTokens.fontFamilyPrimary,
                                  ),
                                )
                              else
                                const SizedBox(height: 14),
                              const SizedBox(height: DesignTokens.spacing4),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                height: height,
                                decoration: BoxDecoration(
                                  gradient: hasData
                                      ? LinearGradient(
                                          colors: [
                                            DesignTokens.accent,
                                            DesignTokens.accent.withValues(alpha: 0.5),
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
                              Text(
                                days[index],
                                style: TextStyle(
                                  color: isToday ? DesignTokens.accent : DesignTokens.textMuted,
                                  fontSize: 10,
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

  Widget _buildDurationDistribution(FocusProvider focus) {
    if (focus.sessions.isEmpty) return const SizedBox.shrink();

    // Bucket sessions by duration
    final buckets = {
      'Under 15m': 0,
      '15-30m': 0,
      '30-45m': 0,
      '45-60m': 0,
      'Over 60m': 0,
    };

    for (final s in focus.sessions.where((s) => s.completed)) {
      final d = s.durationMinutes;
      if (d < 15) buckets['Under 15m'] = buckets['Under 15m']! + 1;
      else if (d < 30) buckets['15-30m'] = buckets['15-30m']! + 1;
      else if (d < 45) buckets['30-45m'] = buckets['30-45m']! + 1;
      else if (d < 60) buckets['45-60m'] = buckets['45-60m']! + 1;
      else buckets['Over 60m'] = buckets['Over 60m']! + 1;
    }

    final maxCount = buckets.values.reduce((a, b) => a > b ? a : b);
    final colors = [
      DesignTokens.accent,
      DesignTokens.success,
      DesignTokens.warning,
      DesignTokens.accentSecondary,
      DesignTokens.danger,
    ];

    return NoraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Session Durations',
            icon: Icons.bar_chart_rounded,
            iconColor: DesignTokens.accentSecondary,
          ),
          const SizedBox(height: DesignTokens.spacing16),
          ...buckets.entries.toList().asMap().entries.map((entry) {
            final index = entry.key;
            final e = entry.value;
            final fraction = maxCount > 0 ? e.value / maxCount : 0.0;
            final color = colors[index % colors.length];
            return Padding(
              padding: const EdgeInsets.only(bottom: DesignTokens.spacing8),
              child: Row(
                children: [
                  SizedBox(
                    width: 70,
                    child: Text(
                      e.key,
                      style: TextStyle(
                        color: DesignTokens.textMuted,
                        fontSize: DesignTokens.fontSizeCaption,
                        fontFamily: DesignTokens.fontFamilyPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: DesignTokens.spacing8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: fraction,
                        minHeight: 8,
                        backgroundColor: DesignTokens.border.withValues(alpha: 0.3),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          fraction > 0 ? color : DesignTokens.border,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: DesignTokens.spacing8),
                  SizedBox(
                    width: 25,
                    child: Text(
                      '${e.value}',
                      style: TextStyle(
                        color: fraction > 0 ? color : DesignTokens.textMuted,
                        fontSize: DesignTokens.fontSizeCaption,
                        fontWeight: DesignTokens.fontWeightBold,
                        fontFamily: DesignTokens.fontFamilyPrimary,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSessionCard(FocusSession session, FocusProvider focus) {
    final date = session.startTime;
    final timeStr = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    final dateStr = '${date.day}/${date.month}/${date.year}';
    final dayName = _getDayName(date.weekday);
    final isCompleted = session.completed;

    return NoraCard(
      backgroundColor: isCompleted
          ? DesignTokens.success.withValues(alpha: 0.04)
          : DesignTokens.surface,
      border: Border.all(
        color: isCompleted
            ? DesignTokens.success.withValues(alpha: 0.2)
            : DesignTokens.border,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          // Status indicator
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: isCompleted ? DesignTokens.success : DesignTokens.warning,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: DesignTokens.spacing12),
          // Time and date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '$session.durationMinutes min',
                      style: TextStyle(
                        color: DesignTokens.textPrimary,
                        fontSize: DesignTokens.fontSizeBody,
                        fontWeight: DesignTokens.fontWeightBold,
                        fontFamily: DesignTokens.fontFamilyPrimary,
                      ),
                    ),
                    const SizedBox(width: DesignTokens.spacing8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: (isCompleted ? DesignTokens.success : DesignTokens.warning)
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(DesignTokens.radius4),
                      ),
                      child: Text(
                        isCompleted ? 'Completed' : 'Partial',
                        style: TextStyle(
                          color: isCompleted ? DesignTokens.success : DesignTokens.warning,
                          fontSize: 10,
                          fontWeight: DesignTokens.fontWeightMedium,
                          fontFamily: DesignTokens.fontFamilyPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: DesignTokens.spacing2),
                Text(
                  '$dayName, $dateStr at $timeStr',
                  style: TextStyle(
                    color: DesignTokens.textMuted,
                    fontSize: DesignTokens.fontSizeCaption,
                    fontFamily: DesignTokens.fontFamilyPrimary,
                  ),
                ),
              ],
            ),
          ),
          // Points earned
          if (session.pointsEarned > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: DesignTokens.warning.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(DesignTokens.radius8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star_rounded, color: DesignTokens.warning, size: 14),
                  const SizedBox(width: 2),
                  Text(
                    '+${session.pointsEarned}',
                    style: TextStyle(
                      color: DesignTokens.warning,
                      fontSize: 12,
                      fontWeight: DesignTokens.fontWeightBold,
                      fontFamily: DesignTokens.fontFamilyPrimary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1: return 'Mon';
      case 2: return 'Tue';
      case 3: return 'Wed';
      case 4: return 'Thu';
      case 5: return 'Fri';
      case 6: return 'Sat';
      case 7: return 'Sun';
      default: return '';
    }
  }
}
