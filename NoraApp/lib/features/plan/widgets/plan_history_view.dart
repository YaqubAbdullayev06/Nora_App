import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/constants/design_tokens.dart';
import '../../../core/enums/age_group.dart';
import '../../../models/models.dart';
import '../../../providers/app_provider.dart';
import '../../../widgets/nora_components.dart';

class PlanHistoryView extends StatelessWidget {
  final AppProvider provider;
  final AgeGroup ageGroup;
  final VoidCallback onBack;

  const PlanHistoryView({
    super.key,
    required this.provider,
    required this.ageGroup,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: DesignTokens.textMuted),
          onPressed: onBack,
        ),
        title: Text(
          'Plan History',
          style: TextStyle(
            color: DesignTokens.textPrimary,
            fontSize: DesignTokens.fontSizeH3,
            fontWeight: DesignTokens.fontWeightSemiBold,
            fontFamily: DesignTokens.fontFamilyDisplay,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: provider.planHistory.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.history_rounded,
                      size: 64,
                      color: DesignTokens.textMuted.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No history yet',
                      style: TextStyle(
                        color: DesignTokens.textMuted,
                        fontSize: DesignTokens.fontSizeBody,
                        fontFamily: DesignTokens.fontFamilyPrimary,
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                itemCount: provider.planHistory.length,
                itemBuilder: (context, index) {
                  return _buildHistoryItem(provider.planHistory[index]);
                },
              ),
      ),
    );
  }

  Widget _buildHistoryItem(DailyPlan plan) {
    final date = plan.date;
    final now = DateTime.now();
    final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
    final isYesterday = date.difference(now).inDays == -1;

    String dateLabel;
    if (isToday) {
      dateLabel = 'Today';
    } else if (isYesterday) {
      dateLabel = 'Yesterday';
    } else {
      dateLabel = '${date.day}/${date.month}/${date.year}';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: NoraCard(
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: plan.allCompleted
                    ? DesignTokens.success.withValues(alpha: 0.15)
                    : DesignTokens.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  '${date.day}',
                  style: TextStyle(
                    color: plan.allCompleted ? DesignTokens.success : DesignTokens.accent,
                    fontSize: DesignTokens.fontSizeH3,
                    fontWeight: DesignTokens.fontWeightBold,
                    fontFamily: DesignTokens.fontFamilyPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dateLabel,
                    style: TextStyle(
                      color: DesignTokens.textPrimary,
                      fontSize: DesignTokens.fontSizeBody,
                      fontWeight: DesignTokens.fontWeightSemiBold,
                      fontFamily: DesignTokens.fontFamilyPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${plan.completedCount}/${plan.tasks.length} tasks completed',
                    style: TextStyle(
                      color: DesignTokens.textMuted,
                      fontSize: DesignTokens.fontSizeCaption,
                      fontFamily: DesignTokens.fontFamilyPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.asset(
                      'assets/images/icons/trophy.svg',
                      width: 14,
                      height: 14,
                      colorFilter: ColorFilter.mode(DesignTokens.warning, BlendMode.srcIn),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '+${plan.pointsEarned}',
                      style: TextStyle(
                        color: DesignTokens.warning,
                        fontSize: DesignTokens.fontSizeCaption,
                        fontWeight: DesignTokens.fontWeightBold,
                        fontFamily: DesignTokens.fontFamilyPrimary,
                      ),
                    ),
                  ],
                ),
                if (plan.eveningReflected)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.asset(
                          'assets/images/icons/moon.svg',
                          width: 12,
                          height: 12,
                          colorFilter: ColorFilter.mode(DesignTokens.accent, BlendMode.srcIn),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Reflected',
                          style: TextStyle(
                            color: DesignTokens.accent,
                            fontSize: DesignTokens.fontSizeTiny,
                            fontFamily: DesignTokens.fontFamilyPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
