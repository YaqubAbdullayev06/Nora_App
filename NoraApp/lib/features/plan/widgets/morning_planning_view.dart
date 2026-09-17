import 'package:flutter/material.dart';
import '../../../core/constants/design_tokens.dart';
import '../../../core/enums/age_group.dart';
import '../../../providers/plan_provider.dart';
import '../../../services/haptic_service.dart';
import '../../../services/task_decomposer.dart';
import '../../../widgets/nora_components.dart';

class MorningPlanningView extends StatefulWidget {
  final AppProvider provider;
  final AgeGroup ageGroup;
  final VoidCallback onShowHistory;

  const MorningPlanningView({
    super.key,
    required this.provider,
    required this.ageGroup,
    required this.onShowHistory,
  });

  @override
  State<MorningPlanningView> createState() => _MorningPlanningViewState();
}

class _MorningPlanningViewState extends State<MorningPlanningView> {
  final List<TextEditingController> _taskControllers = [];

  @override
  void initState() {
    super.initState();
    _initializeControllers(widget.ageGroup.maxDailyTasks);
  }

  @override
  void dispose() {
    for (final c in _taskControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _initializeControllers(int count) {
    while (_taskControllers.length < count) {
      _taskControllers.add(TextEditingController());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.history_rounded, color: DesignTokens.textMuted),
          onPressed: widget.onShowHistory,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              PlanPromptCard(
                title: widget.ageGroup.planTitle,
                subtitle: widget.ageGroup.planSubtitle,
                mascotAsset: widget.ageGroup.planMascotAsset,
              ),
              const SizedBox(height: 32),
              ...List.generate(widget.ageGroup.maxDailyTasks, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildTaskInput(index),
                );
              }),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: NoraButton(
                  label: 'Start My Day',
                  icon: Icons.play_arrow_rounded,
                  expanded: true,
                  onPressed: _submitPlan,
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskInput(int index) {
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
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: priorityColors[index].withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(priorityIcons[index], color: priorityColors[index], size: 18),
          ),
          const SizedBox(width: 12),
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
                            tooltip: 'AI Decompose',
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

  void _submitPlan() {
    final titles = _taskControllers
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    if (titles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter at least one task',
            style: TextStyle(fontFamily: DesignTokens.fontFamilyPrimary),
          ),
          backgroundColor: DesignTokens.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    widget.provider.createDailyPlan(titles);

    for (final c in _taskControllers) {
      c.clear();
    }
  }

  void _decomposeTask(int index) async {
    final text = _taskControllers[index].text.trim();
    if (text.isEmpty) return;

    HapticService.success();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final decomposer = TaskDecomposer();
    final result = await decomposer.decompose(text);

    if (!mounted) return;
    Navigator.of(context).pop();

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
              'AI Subtasks',
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
              if (result.tip.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: DesignTokens.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.lightbulb_outline, size: 16, color: DesignTokens.accent),
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
                              '${subtask.estimatedMinutes}m',
                              style: TextStyle(
                                fontSize: DesignTokens.fontSizeTiny,
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
                    Icon(Icons.timer_outlined, size: 14, color: DesignTokens.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      'Total: ${result.totalEstimatedMinutes} minutes',
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
            child: Text('Cancel', style: TextStyle(color: DesignTokens.textMuted)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _applyDecomposition(result, taskIndex);
            },
            child: Text(
              'Apply',
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

    if (result.subtasks.isNotEmpty) {
      _taskControllers[taskIndex].text = result.subtasks.first.title;
    }

    for (int i = 1;
        i < result.subtasks.length && i < _taskControllers.length;
        i++) {
      _taskControllers[i].text = result.subtasks[i].title;
    }
  }
}
