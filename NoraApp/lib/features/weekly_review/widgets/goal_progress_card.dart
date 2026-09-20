import 'package:flutter/material.dart';
import '../../../core/constants/design_tokens.dart';
import '../../../widgets/nora_components.dart';
import '../../../models/models.dart';

/// Goal Progress Card for Weekly Review.
/// Shows goal title, progress bar, and current/target minutes.
class GoalProgressCard extends StatelessWidget {
  final WeeklyGoal goal;
  final ValueChanged<int>? onProgressChanged;
  final VoidCallback? onDelete;

  const GoalProgressCard({
    super.key,
    required this.goal,
    this.onProgressChanged,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final progressColor = goal.isCompleted
        ? DesignTokens.success
        : DesignTokens.accent;

    return NoraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Goal icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: progressColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(DesignTokens.radius8),
                ),
                child: Icon(
                  goal.isCompleted ? Icons.check_circle_rounded : Icons.flag_rounded,
                  color: progressColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              // Goal title and progress text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.title,
                      style: TextStyle(
                        color: DesignTokens.textPrimary,
                        fontSize: DesignTokens.fontSizeBody,
                        fontWeight: DesignTokens.fontWeightSemiBold,
                        fontFamily: DesignTokens.fontFamilyPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${goal.completedMinutes} / ${goal.targetMinutes} min',
                      style: TextStyle(
                        color: DesignTokens.textMuted,
                        fontSize: DesignTokens.fontSizeCaption,
                        fontFamily: DesignTokens.fontFamilyPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              // Progress percentage
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: progressColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusRound),
                ),
                child: Text(
                  '${(goal.progress * 100).toInt()}%',
                  style: TextStyle(
                    color: progressColor,
                    fontSize: DesignTokens.fontSizeCaption,
                    fontWeight: DesignTokens.fontWeightBold,
                    fontFamily: DesignTokens.fontFamilyPrimary,
                  ),
                ),
              ),
              if (onDelete != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    color: DesignTokens.textMuted,
                    size: 18,
                  ),
                  onPressed: onDelete,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(DesignTokens.radiusRound),
            child: LinearProgressIndicator(
              value: goal.progress,
              minHeight: 8,
              backgroundColor: progressColor.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
          const SizedBox(height: 8),
          // Adjustment buttons
          if (onProgressChanged != null && !goal.isCompleted)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildAdjustButton(
                  icon: Icons.remove_rounded,
                  onTap: () {
                    final newMinutes = (goal.completedMinutes - 5).clamp(0, goal.targetMinutes);
                    onProgressChanged!(newMinutes);
                  },
                ),
                const SizedBox(width: 8),
                _buildAdjustButton(
                  icon: Icons.add_rounded,
                  onTap: () {
                    final newMinutes = (goal.completedMinutes + 5).clamp(0, goal.targetMinutes);
                    onProgressChanged!(newMinutes);
                  },
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildAdjustButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: DesignTokens.surfaceRaised,
          borderRadius: BorderRadius.circular(DesignTokens.radius8),
          border: Border.all(
            color: DesignTokens.border,
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: DesignTokens.textMuted,
          size: 16,
        ),
      ),
    );
  }
}