import 'package:flutter/material.dart';
import '../../../core/constants/design_tokens.dart';
import '../../../providers/app_provider.dart';
import '../../../services/proactive_assist_service.dart';
import '../../../widgets/nora_components.dart';

/// Smart insight card — screen time, social media, blocked apps, suggestions/alerts.
class HomeInsight extends StatelessWidget {
  final SmartSummary summary;

  const HomeInsight({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    return NoraCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              NoraIcon(
                assetPath: 'assets/images/icons/sparkles.svg',
                size: 18,
                color: DesignTokens.accent,
                backgroundColor: DesignTokens.accent.withValues(alpha: 0.15),
                bgSize: 32,
              ),
              const SizedBox(width: 8),
              Text(
                "Today's Insight",
                style: TextStyle(
                  color: DesignTokens.textPrimary,
                  fontSize: DesignTokens.fontSizeBodySmall,
                  fontWeight: DesignTokens.fontWeightSemiBold,
                  fontFamily: DesignTokens.fontFamilyPrimary,
                ),
              ),
              const Spacer(),
              // Focus score badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _getScoreColor(summary.focusScore).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    NoraIcon(
                      assetPath: 'assets/images/icons/star.svg',
                      size: 12,
                      color: _getScoreColor(summary.focusScore),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${summary.focusScore}',
                      style: TextStyle(
                        color: _getScoreColor(summary.focusScore),
                        fontSize: DesignTokens.fontSizeCaption,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Stats row
          Row(
            children: [
              _buildStat('Screen', summary.totalScreenTime, 'assets/images/icons/stats.svg'),
              _buildStat('Social', summary.socialMediaTime, 'assets/images/icons/chat.svg'),
              _buildStat('Blocked', '${summary.blockedAppsCount} apps', 'assets/images/icons/lock.svg'),
            ],
          ),
          // Suggestion
          if (summary.hasSuggestions) ...[
            const SizedBox(height: 12),
            _buildNotice(
              summary.suggestions.first,
              'assets/images/icons/sparkles.svg',
              DesignTokens.success,
            ),
          ],
          // Alert
          if (summary.hasAlerts) ...[
            const SizedBox(height: 8),
            _buildNotice(
              summary.alerts.first,
              'assets/images/icons/fire.svg',
              DesignTokens.danger,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, String iconAsset) {
    return Expanded(
      child: Column(
        children: [
          NoraIcon(
            assetPath: iconAsset,
            size: 16,
            color: DesignTokens.textMuted,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: DesignTokens.textPrimary,
              fontSize: DesignTokens.fontSizeCaption,
              fontWeight: DesignTokens.fontWeightSemiBold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: DesignTokens.textMuted,
              fontSize: DesignTokens.fontSizeTiny,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotice(String text, String iconAsset, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          NoraIcon(assetPath: iconAsset, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: DesignTokens.fontSizeCaption,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return DesignTokens.success;
    if (score >= 50) return DesignTokens.warning;
    return DesignTokens.danger;
  }
}
