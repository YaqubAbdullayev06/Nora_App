import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/design_tokens.dart';
import '../../../core/enums/age_group.dart';
import '../../../providers/app_provider.dart';
import '../../../widgets/nora_components.dart';
import '../widgets/morning_planning_view.dart';
import '../widgets/evening_reflection_view.dart';
import '../widgets/plan_history_view.dart';

class PlanScreen extends StatefulWidget {
  const PlanScreen({super.key});

  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {
  bool _showHistory = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializePlan();
    });
  }

  void _initializePlan() {
    final provider = context.read<AppProvider>();
    provider.loadTodayPlan();
    provider.loadPlanHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final ageGroup = provider.ageGroup;
        final hasPlanned = provider.hasPlannedToday;
        final hasReflected = provider.hasReflectedToday;
        final isEvening = provider.isEveningTime;

        if (_showHistory) {
          return PlanHistoryView(
            provider: provider,
            ageGroup: ageGroup,
            onBack: () => setState(() => _showHistory = false),
          );
        }

        if (!hasPlanned) {
          return MorningPlanningView(
            provider: provider,
            ageGroup: ageGroup,
            onShowHistory: () => setState(() => _showHistory = true),
          );
        }

        if (isEvening && !hasReflected) {
          return EveningReflectionView(provider: provider, ageGroup: ageGroup);
        }

        return _buildActiveDay(provider, ageGroup);
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // STATE 2: ACTIVE DAY
  // ═══════════════════════════════════════════════════════════════

  Widget _buildActiveDay(AppProvider provider, AgeGroup ageGroup) {
    final plan = provider.todayPlan!;
    final allDone = plan.allCompleted;

    return Scaffold(
      backgroundColor: DesignTokens.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Today's Priorities",
          style: TextStyle(
            color: DesignTokens.textPrimary,
            fontSize: DesignTokens.fontSizeH3,
            fontWeight: DesignTokens.fontWeightSemiBold,
            fontFamily: DesignTokens.fontFamilyDisplay,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.history_rounded,
            color: DesignTokens.textMuted,
          ),
          onPressed: () => setState(() => _showHistory = true),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Progress section
              _buildProgressSection(provider, ageGroup, allDone),
              const SizedBox(height: 24),
              // Task list
              ...plan.tasks.map((task) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: PlanTaskCard(
                    task: task,
                    onToggle: () => provider.toggleTask(task.id),
                  ),
                );
              }),
              const SizedBox(height: 24),
              // Start focus button
              if (!allDone)
                SizedBox(
                  width: double.infinity,
                  child: NoraButton(
                    label: 'Start Focus Session',
                    icon: Icons.timer_rounded,
                    expanded: true,
                    onPressed: () {
                      // Navigate to timer
                      Navigator.pushNamed(context, '/timer');
                    },
                  ),
                ),
              // All done celebration
              if (allDone) _buildAllDoneMessage(ageGroup),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressSection(
      AppProvider provider, AgeGroup ageGroup, bool allDone) {
    return NoraCard(
      gradient: LinearGradient(
        colors: [
          DesignTokens.accent.withValues(alpha: 0.1),
          DesignTokens.accentSecondary.withValues(alpha: 0.1),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Row(
        children: [
          PlanProgressRing(
            completed: provider.completedTasksToday,
            total: provider.totalTasksToday,
            size: 72,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  allDone ? 'All Done!' : 'Keep Going!',
                  style: TextStyle(
                    color: DesignTokens.textPrimary,
                    fontSize: DesignTokens.fontSizeH3,
                    fontWeight: DesignTokens.fontWeightBold,
                    fontFamily: DesignTokens.fontFamilyDisplay,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${provider.completedTasksToday} of ${provider.totalTasksToday} tasks completed',
                  style: TextStyle(
                    color: DesignTokens.textMuted,
                    fontSize: DesignTokens.fontSizeBodySmall,
                    fontFamily: DesignTokens.fontFamilyPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                // Points earned
                Row(
                  children: [
                    SvgPicture.asset(
                      'assets/images/icons/trophy.svg',
                      width: 16,
                      height: 16,
                      colorFilter: ColorFilter.mode(
                        DesignTokens.warning,
                        BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '+${provider.pointsEarnedToday} points',
                      style: TextStyle(
                        color: DesignTokens.warning,
                        fontSize: DesignTokens.fontSizeCaption,
                        fontWeight: DesignTokens.fontWeightBold,
                        fontFamily: DesignTokens.fontFamilyPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllDoneMessage(AgeGroup ageGroup) {
    String message;
    String subtitle;
    IconData icon;

    switch (ageGroup) {
      case AgeGroup.baby:
        message = 'Great Job!';
        subtitle = 'You completed all your activities!';
        icon = Icons.star_rounded;
        break;
      case AgeGroup.child:
        message = 'Great Job!';
        subtitle = 'You completed all your activities!';
        icon = Icons.star_rounded;
        break;
      case AgeGroup.kid:
        message = 'Quest Complete!';
        subtitle = 'All quests finished. You earned bonus XP!';
        icon = Icons.emoji_events_rounded;
        break;
      case AgeGroup.teen:
        message = 'Mission Accomplished!';
        subtitle = 'All priorities done. Keep the momentum!';
        icon = Icons.rocket_launch_rounded;
        break;
      case AgeGroup.adult:
        message = 'Day Complete!';
        subtitle = 'All priorities achieved. Well done.';
        icon = Icons.check_circle_rounded;
        break;
    }

    return NoraCard(
      gradient: LinearGradient(
        colors: [
          DesignTokens.success.withValues(alpha: 0.15),
          DesignTokens.success.withValues(alpha: 0.05),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 48,
            color: DesignTokens.success,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              color: DesignTokens.textPrimary,
              fontSize: DesignTokens.fontSizeH2,
              fontWeight: DesignTokens.fontWeightBold,
              fontFamily: DesignTokens.fontFamilyDisplay,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: DesignTokens.textMuted,
              fontSize: DesignTokens.fontSizeBody,
              fontFamily: DesignTokens.fontFamilyPrimary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

}
