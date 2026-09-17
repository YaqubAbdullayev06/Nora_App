import 'package:flutter/material.dart';
import '../../../core/constants/design_tokens.dart';
import '../../../widgets/nora_components.dart';

/// Weekly Summary Card for Weekly Review.
/// Shows key stats for the week: focus time, sessions, points, streak.
class WeeklySummaryCard extends StatelessWidget {
  final int totalFocusMinutes;
  final int totalSessions;
  final int totalPointsEarned;
  final int streakDays;
  final int daysActive;

  const WeeklySummaryCard({
    super.key,
    required this.totalFocusMinutes,
    required this.totalSessions,
    required this.totalPointsEarned,
    required this.streakDays,
    this.daysActive = 0,
  });

  @override
  Widget build(BuildContext context) {
    return NoraCard(
      gradient: LinearGradient(
        colors: [
          DesignTokens.accent,
          DesignTokens.accentSecondary,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(DesignTokens.radius8),
                ),
                child: const Icon(
                  Icons.analytics_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Weekly Summary',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: DesignTokens.fontSizeBody,
                  fontWeight: DesignTokens.fontWeightBold,
                  fontFamily: DesignTokens.fontFamilyDisplay,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                icon: Icons.timer_rounded,
                value: _formatMinutes(totalFocusMinutes),
                label: 'Focus',
              ),
              _buildStatItem(
                icon: Icons.play_circle_rounded,
                value: '$totalSessions',
                label: 'Sessions',
              ),
              _buildStatItem(
                icon: Icons.star_rounded,
                value: '$totalPointsEarned',
                label: 'Points',
              ),
              _buildStatItem(
                icon: Icons.local_fire_department_rounded,
                value: '$streakDays',
                label: 'Streak',
              ),
            ],
          ),
          if (daysActive > 0) ...[
            const SizedBox(height: 16),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusRound),
                ),
                child: Text(
                  '$daysActive of 7 days active',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: DesignTokens.fontSizeCaption,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(DesignTokens.radius8),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: DesignTokens.fontSizeSubhead,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: DesignTokens.fontSizeExtraSmall,
          ),
        ),
      ],
    );
  }

  String _formatMinutes(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return mins > 0 ? '${hours}h ${mins}m' : '${hours}h';
  }
}