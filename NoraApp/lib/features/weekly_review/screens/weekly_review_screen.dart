import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/constants/design_tokens.dart';
import '../../../core/enums/age_group.dart';
import '../../../providers/app_provider.dart';
import '../../../models/models.dart';
import '../../../widgets/nora_components.dart';
import '../widgets/mood_selector.dart';
import '../widgets/goal_progress_card.dart';
import '../widgets/reflection_card.dart';
import '../widgets/weekly_summary_card.dart';
import '../widgets/ai_insight_card.dart';

/// Weekly Review Screen
/// A comprehensive weekly reflection and planning experience.
/// Adapts to all 4 age personas (Baby, Kid, Teen, Adult).
class WeeklyReviewScreen extends StatefulWidget {
  const WeeklyReviewScreen({super.key});

  @override
  State<WeeklyReviewScreen> createState() => _WeeklyReviewScreenState();
}

class _WeeklyReviewScreenState extends State<WeeklyReviewScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final review = provider.getOrCreateCurrentWeeklyReview();
        final weeklyMinutes = provider.weeklyFocusMinutes;
        final daysActive = weeklyMinutes.where((m) => m > 0).length;

        return Scaffold(
          backgroundColor: DesignTokens.background,
          body: SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: CustomScrollView(
                  slivers: [
                    // App Bar
                    _buildAppBar(context, provider),
                    // Content
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          const SizedBox(height: 8),
                          // Weekly Summary Card
                          WeeklySummaryCard(
                            totalFocusMinutes: review.totalFocusMinutes,
                            totalSessions: review.totalSessions,
                            totalPointsEarned: review.totalPointsEarned,
                            streakDays: review.streakDays,
                            daysActive: daysActive,
                          ),
                          const SizedBox(height: 24),
                          // Mood Selector
                          MoodSelector(
                            selectedMood: review.mood,
                            onMoodSelected: (mood) {
                              provider.setWeeklyMood(mood);
                            },
                          ),
                          const SizedBox(height: 24),
                          // Goals Section
                          _buildGoalsSection(context, provider, review),
                          const SizedBox(height: 24),
                          // Reflections Section
                          _buildReflectionsSection(context, provider, review),
                          const SizedBox(height: 24),
                          // AI Insight
                          AiInsightCard(
                            insight: review.aiInsight,
                            isLoading: false,
                            onRefresh: () => _generateAiInsight(provider, review),
                          ),
                          const SizedBox(height: 24),
                          // Week Visualization
                          _buildWeekVisualization(context, weeklyMinutes),
                          const SizedBox(height: 24),
                          // Save Button
                          _buildSaveButton(context, provider),
                          const SizedBox(height: 32),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppBar(BuildContext context, AppProvider provider) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              DesignTokens.accent.withValues(alpha: 0.15),
              DesignTokens.background,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: DesignTokens.surfaceRaised,
                      borderRadius: BorderRadius.circular(DesignTokens.radius12),
                      border: Border.all(
                        color: DesignTokens.border,
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: DesignTokens.textPrimary,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getAgeAdaptiveTitle(provider.ageGroup),
                        style: TextStyle(
                          color: DesignTokens.textPrimary,
                          fontSize: DesignTokens.fontSizeH2,
                          fontWeight: DesignTokens.fontWeightBold,
                          fontFamily: DesignTokens.fontFamilyDisplay,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_formatDate(startOfWeek)} - ${_formatDate(endOfWeek)}',
                        style: TextStyle(
                          color: DesignTokens.textMuted,
                          fontSize: DesignTokens.fontSizeCaption,
                          fontFamily: DesignTokens.fontFamilyPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Mascot
                NoraMascot(size: 48, showGlow: false),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getAgeAdaptiveTitle(AgeGroup ageGroup) {
    switch (ageGroup) {
      case AgeGroup.baby:
        return 'My Happy Week!';
      case AgeGroup.kid:
        return 'Weekly Adventure Review';
      case AgeGroup.teen:
        return 'Weekly Check-In';
      case AgeGroup.adult:
        return 'Weekly Review';
    }
  }

  Widget _buildGoalsSection(
    BuildContext context,
    AppProvider provider,
    WeeklyReview review,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SectionHeader(
              title: _getAgeAdaptiveGoalsTitle(provider.ageGroup),
              icon: Icons.flag_rounded,
              iconColor: DesignTokens.accent,
            ),
            GestureDetector(
              onTap: () => _showAddGoalDialog(context, provider),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: DesignTokens.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(DesignTokens.radius8),
                ),
                child: Icon(
                  Icons.add_rounded,
                  color: DesignTokens.accent,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (review.goals.isEmpty)
          _buildEmptyGoalsState(provider.ageGroup)
        else
          ...review.goals.map((goal) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GoalProgressCard(
                  goal: goal,
                  onProgressChanged: (minutes) {
                    provider.updateWeeklyGoalProgress(goal.id, minutes);
                  },
                  onDelete: () => provider.removeWeeklyGoal(goal.id),
                ),
              )),
      ],
    );
  }

  String _getAgeAdaptiveGoalsTitle(AgeGroup ageGroup) {
    switch (ageGroup) {
      case AgeGroup.baby:
        return 'My Goals';
      case AgeGroup.kid:
        return 'Weekly Goals';
      case AgeGroup.teen:
        return 'Goals & Targets';
      case AgeGroup.adult:
        return 'Weekly Goals';
    }
  }

  Widget _buildEmptyGoalsState(AgeGroup ageGroup) {
    String message;
    switch (ageGroup) {
      case AgeGroup.baby:
        message = 'No goals yet! Tap + to add fun activities.';
        break;
      case AgeGroup.kid:
        message = 'No goals yet! Add some cool challenges!';
        break;
      case AgeGroup.teen:
        message = 'Set your weekly targets to stay on track.';
        break;
      case AgeGroup.adult:
        message = 'Define your weekly goals to maximize productivity.';
        break;
    }

    return NoraCard(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                Icons.flag_outlined,
                color: DesignTokens.textMuted,
                size: 32,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: DesignTokens.textMuted,
                  fontSize: DesignTokens.fontSizeBodySmall,
                  fontFamily: DesignTokens.fontFamilyPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReflectionsSection(
    BuildContext context,
    AppProvider provider,
    WeeklyReview review,
  ) {
    final prompts = WeeklyReview.getReflectionPrompts(provider.ageGroup);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: _getAgeAdaptiveReflectionsTitle(provider.ageGroup),
          icon: Icons.psychology_rounded,
          iconColor: DesignTokens.accentTertiary,
        ),
        const SizedBox(height: 12),
        ...prompts.asMap().entries.map((entry) {
          final index = entry.key;
          final question = entry.value;
          final existingReflection = review.reflections.length > index
              ? review.reflections[index]
              : null;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ReflectionCard(
              question: question,
              existingAnswer: existingReflection?.answer,
              onAnswerSubmitted: (answer) {
                provider.addWeeklyReflection(question, answer);
              },
            ),
          );
        }),
      ],
    );
  }

  String _getAgeAdaptiveReflectionsTitle(AgeGroup ageGroup) {
    switch (ageGroup) {
      case AgeGroup.baby:
        return 'Happy Thoughts';
      case AgeGroup.kid:
        return 'Reflection Time';
      case AgeGroup.teen:
        return 'Weekly Reflection';
      case AgeGroup.adult:
        return 'Reflection & Insights';
    }
  }

  Widget _buildWeekVisualization(BuildContext context, List<int> weeklyMinutes) {
    final maxMinutes = weeklyMinutes.reduce((a, b) => a > b ? a : b);
    final dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return NoraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Focus Activity',
            icon: Icons.bar_chart_rounded,
            iconColor: DesignTokens.accent,
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(7, (index) {
                final minutes = weeklyMinutes[index];
                final height = maxMinutes > 0
                    ? (minutes / maxMinutes) * 80
                    : 0.0;
                final isToday = index == DateTime.now().weekday - 1;

                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (minutes > 0)
                      Text(
                        '${minutes}m',
                        style: TextStyle(
                          color: DesignTokens.textMuted,
                          fontSize: 10,
                        ),
                      ),
                    const SizedBox(height: 4),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 28,
                      height: height.clamp(4.0, 80.0),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isToday
                              ? [DesignTokens.accent, DesignTokens.accentSecondary]
                              : [
                                  DesignTokens.accent.withValues(alpha: 0.5),
                                  DesignTokens.accentSecondary.withValues(alpha: 0.5),
                                ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(DesignTokens.radius8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      dayLabels[index],
                      style: TextStyle(
                        color: isToday
                            ? DesignTokens.accent
                            : DesignTokens.textMuted,
                        fontSize: 11,
                        fontWeight:
                            isToday ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(BuildContext context, AppProvider provider) {
    return NoraButton(
      label: _getAgeAdaptiveSaveLabel(provider.ageGroup),
      icon: Icons.save_rounded,
      expanded: true,
      height: 52,
      onPressed: () => _saveWeeklyReview(context, provider),
    );
  }

  String _getAgeAdaptiveSaveLabel(AgeGroup ageGroup) {
    switch (ageGroup) {
      case AgeGroup.baby:
        return 'Save My Week!';
      case AgeGroup.kid:
        return 'Save My Review!';
      case AgeGroup.teen:
        return 'Save Weekly Review';
      case AgeGroup.adult:
        return 'Save Weekly Review';
    }
  }

  void _showAddGoalDialog(BuildContext context, AppProvider provider) {
    final titleController = TextEditingController();
    final minutesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: DesignTokens.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
        ),
        title: Text(
          'Add New Goal',
          style: TextStyle(
            color: DesignTokens.textPrimary,
            fontWeight: DesignTokens.fontWeightBold,
            fontFamily: DesignTokens.fontFamilyDisplay,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              style: TextStyle(color: DesignTokens.textPrimary),
              decoration: InputDecoration(
                hintText: 'Goal title',
                hintStyle: TextStyle(color: DesignTokens.textMuted),
                filled: true,
                fillColor: DesignTokens.surfaceRaised,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
                  borderSide: BorderSide(color: DesignTokens.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
                  borderSide: BorderSide(color: DesignTokens.border),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: minutesController,
              keyboardType: TextInputType.number,
              style: TextStyle(color: DesignTokens.textPrimary),
              decoration: InputDecoration(
                hintText: 'Target minutes',
                hintStyle: TextStyle(color: DesignTokens.textMuted),
                filled: true,
                fillColor: DesignTokens.surfaceRaised,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
                  borderSide: BorderSide(color: DesignTokens.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
                  borderSide: BorderSide(color: DesignTokens.border),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: DesignTokens.textMuted),
            ),
          ),
          NoraButton(
            label: 'Add',
            icon: Icons.add_rounded,
            onPressed: () {
              final title = titleController.text.trim();
              final minutes = int.tryParse(minutesController.text) ?? 0;
              if (title.isNotEmpty && minutes > 0) {
                provider.addWeeklyGoal(title, minutes);
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }

  void _saveWeeklyReview(BuildContext context, AppProvider provider) {
    provider.saveWeeklyReview();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _getAgeAdaptiveSaveMessage(provider.ageGroup),
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: DesignTokens.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );

    Navigator.pop(context);
  }

  String _getAgeAdaptiveSaveMessage(AgeGroup ageGroup) {
    switch (ageGroup) {
      case AgeGroup.baby:
        return 'Great job! Your happy week is saved!';
      case AgeGroup.kid:
        return 'Awesome review saved! Keep being amazing!';
      case AgeGroup.teen:
        return 'Weekly review saved! Keep crushing it!';
      case AgeGroup.adult:
        return 'Weekly review saved successfully!';
    }
  }

  void _generateAiInsight(AppProvider provider, WeeklyReview review) {
    // Generate a simple insight based on the data
    String insight;
    if (review.totalFocusMinutes == 0) {
      insight = 'Start focusing this week to get personalized insights!';
    } else if (review.totalFocusMinutes < 60) {
      insight =
          'You focused for ${review.totalFocusMinutes} minutes this week. Try to increase your focus time by 10% next week for steady improvement.';
    } else if (review.totalFocusMinutes < 180) {
      insight =
          'Great progress! ${review.totalFocusMinutes ~/ 60} hours of focus time. Your consistency is building. Consider adding reflection time to deepen your learning.';
    } else {
      insight =
          'Impressive week! ${review.totalFocusMinutes ~/ 60}+ hours of deep focus. You\'re building powerful habits. Keep maintaining this momentum!';
    }

    provider.setWeeklyAiInsight(insight);
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }
}