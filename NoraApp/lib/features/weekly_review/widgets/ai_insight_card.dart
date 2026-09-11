import 'package:flutter/material.dart';
import '../../../core/constants/design_tokens.dart';
import '../../../widgets/nora_components.dart';

/// AI Insight Card for Weekly Review.
/// Displays AI-generated insights about the user's week.
class AiInsightCard extends StatelessWidget {
  final String? insight;
  final bool isLoading;
  final VoidCallback? onRefresh;

  const AiInsightCard({
    super.key,
    this.insight,
    this.isLoading = false,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return NoraCard(
      backgroundColor: DesignTokens.surfaceRaised,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      DesignTokens.accent,
                      DesignTokens.accentSecondary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(DesignTokens.radius8),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'AI Weekly Insight',
                  style: TextStyle(
                    color: DesignTokens.textPrimary,
                    fontSize: DesignTokens.fontSizeBody,
                    fontWeight: DesignTokens.fontWeightSemiBold,
                    fontFamily: DesignTokens.fontFamilyDisplay,
                  ),
                ),
              ),
              if (onRefresh != null)
                IconButton(
                  icon: Icon(
                    Icons.refresh_rounded,
                    color: DesignTokens.textMuted,
                    size: 20,
                  ),
                  onPressed: onRefresh,
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (isLoading)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          DesignTokens.accent,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Analyzing your week...',
                      style: TextStyle(
                        color: DesignTokens.textMuted,
                        fontSize: DesignTokens.fontSizeCaption,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (insight != null && insight!.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: DesignTokens.accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(DesignTokens.radius12),
                border: Border.all(
                  color: DesignTokens.accent.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Text(
                insight!,
                style: TextStyle(
                  color: DesignTokens.textPrimary,
                  fontSize: DesignTokens.fontSizeBodySmall,
                  fontFamily: DesignTokens.fontFamilyPrimary,
                  height: 1.5,
                ),
              ),
            )
          else
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      Icons.lightbulb_outline_rounded,
                      color: DesignTokens.textMuted,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Complete your reflections to get\npersonalized AI insights',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: DesignTokens.textMuted,
                        fontSize: DesignTokens.fontSizeCaption,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}