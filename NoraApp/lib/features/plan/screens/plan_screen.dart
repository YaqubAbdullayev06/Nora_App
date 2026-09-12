import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/design_tokens.dart';
import '../../../core/enums/age_group.dart';
import '../../../models/models.dart';
import '../../../providers/app_provider.dart';
import '../../../services/haptic_service.dart';
import '../../../services/task_decomposer.dart';
import '../../../widgets/nora_components.dart';

class PlanScreen extends StatefulWidget {
  const PlanScreen({super.key});

  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {
  final List<TextEditingController> _taskControllers = [];
  final TextEditingController _reflectionController = TextEditingController();
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
  void dispose() {
    for (final c in _taskControllers) {
      c.dispose();
    }
    _reflectionController.dispose();
    super.dispose();
  }

  void _initializeControllers(int count) {
    while (_taskControllers.length < count) {
      _taskControllers.add(TextEditingController());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final ageGroup = provider.ageGroup;
        final hasPlanned = provider.hasPlannedToday;
        final hasReflected = provider.hasReflectedToday;
        final isEvening = provider.isEveningTime;

        // Determine which state to show
        if (_showHistory) {
          return _buildHistoryView(provider, ageGroup);
        }

        if (!hasPlanned) {
          // State 1: Morning Planning
          return _buildMorningPlanning(provider, ageGroup);
        }

        if (isEvening && !hasReflected) {
          // State 3: Evening Reflection
          return _buildEveningReflection(provider, ageGroup);
        }

        // State 2: Active Day
        return _buildActiveDay(provider, ageGroup);
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // STATE 1: MORNING PLANNING
  // ═══════════════════════════════════════════════════════════════

  Widget _buildMorningPlanning(AppProvider provider, AgeGroup ageGroup) {
    _initializeControllers(ageGroup.maxDailyTasks);

    return Scaffold(
      backgroundColor: DesignTokens.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
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
              // Mascot and prompt
              PlanPromptCard(
                title: ageGroup.planTitle,
                subtitle: ageGroup.planSubtitle,
                mascotAsset: ageGroup.planMascotAsset,
              ),
              const SizedBox(height: 32),
              // Task inputs
              ...List.generate(ageGroup.maxDailyTasks, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildTaskInput(index, provider),
                );
              }),
              const SizedBox(height: 24),
              // Start button
              SizedBox(
                width: double.infinity,
                child: NoraButton(
                  label: 'Start My Day',
                  icon: Icons.play_arrow_rounded,
                  expanded: true,
                  onPressed: () => _submitPlan(provider),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskInput(int index, AppProvider provider) {
    final priorityColors = [
      DesignTokens.danger,
      DesignTokens.warning,
      DesignTokens.success,
    ];
    final priorityLabels = ['Must do', 'Should do', 'Nice to do'];
    final priorityIcons = [
      Icons.priority_high_rounded,
      Icons.remove_rounded,
      Icons.arrow_downward_rounded,
    ];

    return NoraCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          // Priority indicator
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: priorityColors[index].withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              priorityIcons[index],
              color: priorityColors[index],
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          // Input field
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  priorityLabels[index],
                  style: TextStyle(
                    color: priorityColors[index],
                    fontSize: DesignTokens.fontSizeCaption,
                    fontWeight: DesignTokens.fontWeightMedium,
                    fontFamily: DesignTokens.fontFamilyPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: _taskControllers[index],
                  style: TextStyle(
                    color: DesignTokens.textPrimary,
                    fontSize: DesignTokens.fontSizeBody,
                    fontFamily: DesignTokens.fontFamilyPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'What needs to be done?',
                    hintStyle: TextStyle(
                      color: DesignTokens.textMuted,
                      fontSize: DesignTokens.fontSizeBody,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    suffixIcon: _taskControllers[index].text.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.auto_fix_high,
                              size: 18,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            onPressed: () => _decomposeTask(index),
                            tooltip: "AI Decompose",
                          )
                        : null,
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _submitPlan(AppProvider provider) {
    final titles = _taskControllers
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    if (titles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter at least one task',
            style: TextStyle(
              fontFamily: DesignTokens.fontFamilyPrimary,
            ),
          ),
          backgroundColor: DesignTokens.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    provider.createDailyPlan(titles);

    // Clear controllers
    for (final c in _taskControllers) {
      c.clear();
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // AI TASK DECOMPOSITION
  // ═══════════════════════════════════════════════════════════════

  void _decomposeTask(int index) async {
    final text = _taskControllers[index].text.trim();
    if (text.isEmpty) return;

    HapticService.success();

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    final decomposer = TaskDecomposer();
    final result = await decomposer.decompose(text);

    if (!mounted) return;
    Navigator.of(context).pop(); // dismiss loading

    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not decompose task. Try again or enter subtasks manually.',
            style: TextStyle(fontFamily: DesignTokens.fontFamilyPrimary),
          ),
          backgroundColor: DesignTokens.danger,
        ),
      );
      return;
    }

    // Show decomposition result
    _showDecompositionDialog(result, index);
  }

  void _showDecompositionDialog(DecomposedTask result, int taskIndex) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: DesignTokens.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radius16),
        ),
        title: Row(
          children: [
            const Icon(Icons.auto_fix_high, size: 20),
            const SizedBox(width: 8),
            Text(
              "AI Subtasks",
              style: TextStyle(
                color: DesignTokens.textPrimary,
                fontFamily: DesignTokens.fontFamilyDisplay,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tip
              if (result.tip.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: DesignTokens.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.lightbulb_outline,
                          size: 16, color: DesignTokens.accent),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          result.tip,
                          style: TextStyle(
                            color: DesignTokens.textMuted,
                            fontSize: DesignTokens.fontSizeCaption,
                            fontFamily: DesignTokens.fontFamilyPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              // Subtasks list
              ...result.subtasks.map((subtask) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: subtask.priority == 1
                                ? DesignTokens.danger.withValues(alpha: 0.15)
                                : subtask.priority == 2
                                    ? DesignTokens.warning.withValues(alpha: 0.15)
                                    : DesignTokens.success.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Center(
                            child: Text(
                              "${subtask.estimatedMinutes}m",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: subtask.priority == 1
                                    ? DesignTokens.danger
                                    : subtask.priority == 2
                                        ? DesignTokens.warning
                                        : DesignTokens.success,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                subtask.title,
                                style: TextStyle(
                                  color: DesignTokens.textPrimary,
                                  fontSize: DesignTokens.fontSizeBody,
                                  fontFamily: DesignTokens.fontFamilyPrimary,
                                ),
                              ),
                              if (subtask.description.isNotEmpty)
                                Text(
                                  subtask.description,
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
                  )),
              // Total time
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: DesignTokens.surfaceRaised,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.timer_outlined,
                        size: 14, color: DesignTokens.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      "Total: ${result.totalEstimatedMinutes} minutes",
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
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              "Cancel",
              style: TextStyle(color: DesignTokens.textMuted),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _applyDecomposition(result, taskIndex);
            },
            child: Text(
              "Apply",
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _applyDecomposition(DecomposedTask result, int taskIndex) {
    HapticService.timerStarted();

    // Fill the current task slot with the first subtask
    if (result.subtasks.isNotEmpty) {
      _taskControllers[taskIndex].text = result.subtasks.first.title;
    }

    // Fill additional slots with remaining subtasks (if available)
    for (int i = 1;
        i < result.subtasks.length && i < _taskControllers.length;
        i++) {
      _taskControllers[i].text = result.subtasks[i].title;
    }
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

  // ═══════════════════════════════════════════════════════════════
  // STATE 3: EVENING REFLECTION
  // ═══════════════════════════════════════════════════════════════

  Widget _buildEveningReflection(AppProvider provider, AgeGroup ageGroup) {
    return Scaffold(
      backgroundColor: DesignTokens.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          ageGroup.reflectionLabel,
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Day summary
              _buildDaySummary(provider, ageGroup),
              const SizedBox(height: 24),
              // Reflection prompt
              _buildReflectionInput(ageGroup),
              const SizedBox(height: 24),
              // Save button
              SizedBox(
                width: double.infinity,
                child: NoraButton(
                  label: 'Save Reflection',
                  icon: Icons.check_rounded,
                  expanded: true,
                  onPressed: () => _submitReflection(provider),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDaySummary(AppProvider provider, AgeGroup ageGroup) {
    return NoraCard(
      child: Column(
        children: [
          // Mascot
          SizedBox(
            width: 64,
            height: 64,
            child: SvgPicture.asset(
              ageGroup.planMascotAsset,
              fit: BoxFit.contain,
              placeholderBuilder: (context) => Center(
                child: Icon(
                  Icons.star_rounded,
                  size: 40,
                  color: DesignTokens.accent.withValues(alpha: 0.6),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem(
                Icons.check_circle_rounded,
                '${provider.completedTasksToday}/${provider.totalTasksToday}',
                'Tasks',
                DesignTokens.success,
              ),
              _buildStatItem(
                Icons.star_rounded,
                '${provider.pointsEarnedToday}',
                'Points',
                DesignTokens.warning,
              ),
              _buildStatItem(
                Icons.local_fire_department_rounded,
                '${provider.streakDays}',
                'Streak',
                DesignTokens.danger,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: DesignTokens.textPrimary,
            fontSize: DesignTokens.fontSizeH3,
            fontWeight: DesignTokens.fontWeightBold,
            fontFamily: DesignTokens.fontFamilyPrimary,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: DesignTokens.textMuted,
            fontSize: DesignTokens.fontSizeCaption,
            fontFamily: DesignTokens.fontFamilyPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildReflectionInput(AgeGroup ageGroup) {
    String hint;
    int maxLines;

    switch (ageGroup) {
      case AgeGroup.baby:
        hint = 'What was your favorite part today?';
        maxLines = 2;
        break;
      case AgeGroup.child:
        hint = 'What was your favorite part today?';
        maxLines = 2;
        break;
      case AgeGroup.kid:
        hint = 'What did you learn today?';
        maxLines = 3;
        break;
      case AgeGroup.teen:
        hint = 'Reflect on your day...';
        maxLines = 4;
        break;
      case AgeGroup.adult:
        hint = 'How did today go? What went well? What could be improved?';
        maxLines = 5;
        break;
    }

    return NoraCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SvgPicture.asset(
                'assets/images/icons/moon.svg',
                width: 20,
                height: 20,
                colorFilter: ColorFilter.mode(
                  DesignTokens.accent,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Evening Reflection',
                style: TextStyle(
                  color: DesignTokens.textPrimary,
                  fontSize: DesignTokens.fontSizeBody,
                  fontWeight: DesignTokens.fontWeightSemiBold,
                  fontFamily: DesignTokens.fontFamilyPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _reflectionController,
            style: TextStyle(
              color: DesignTokens.textPrimary,
              fontSize: DesignTokens.fontSizeBody,
              fontFamily: DesignTokens.fontFamilyPrimary,
            ),
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: DesignTokens.textMuted,
                fontSize: DesignTokens.fontSizeBody,
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
            textCapitalization: TextCapitalization.sentences,
          ),
        ],
      ),
    );
  }

  void _submitReflection(AppProvider provider) {
    final note = _reflectionController.text.trim();
    provider.submitReflection(note);
    _reflectionController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Reflection saved! Great job today.',
          style: TextStyle(
            fontFamily: DesignTokens.fontFamilyPrimary,
          ),
        ),
        backgroundColor: DesignTokens.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // STATE 4: HISTORY VIEW
  // ═══════════════════════════════════════════════════════════════

  Widget _buildHistoryView(AppProvider provider, AgeGroup ageGroup) {
    return Scaffold(
      backgroundColor: DesignTokens.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: DesignTokens.textMuted,
          ),
          onPressed: () => setState(() => _showHistory = false),
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
                  final plan = provider.planHistory[index];
                  return _buildHistoryItem(plan, ageGroup);
                },
              ),
      ),
    );
  }

  Widget _buildHistoryItem(DailyPlan plan, AgeGroup ageGroup) {
    final date = plan.date;
    final now = DateTime.now();
    final isToday = date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
    final isYesterday = date.difference(now).inDays == -1;

    String dateLabel;
    if (isToday) {
      dateLabel = 'Today';
    } else if (isYesterday) {
      dateLabel = 'Yesterday';
    } else {
      dateLabel =
          '${date.day}/${date.month}/${date.year}';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: NoraCard(
        child: Row(
          children: [
            // Date circle
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
                    color: plan.allCompleted
                        ? DesignTokens.success
                        : DesignTokens.accent,
                    fontSize: DesignTokens.fontSizeH3,
                    fontWeight: DesignTokens.fontWeightBold,
                    fontFamily: DesignTokens.fontFamilyPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Info
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
            // Points
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
                      colorFilter: ColorFilter.mode(
                        DesignTokens.warning,
                        BlendMode.srcIn,
                      ),
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
                          colorFilter: ColorFilter.mode(
                            DesignTokens.accent,
                            BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Reflected',
                          style: TextStyle(
                            color: DesignTokens.accent,
                            fontSize: 10,
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
