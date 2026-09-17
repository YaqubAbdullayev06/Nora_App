import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/design_tokens.dart';
import '../../../models/models.dart';
import '../../../providers/habit_provider.dart';
import '../../../providers/hard_cap_provider.dart';
import '../../../widgets/nora_components.dart';
import '../../../widgets/nora_loading.dart';

/// Habits Screen — Manage real-world habits that earn screen time.
///
/// Shows:
/// - Today's earned screen time
/// - Habits list with completion status
/// - Add new habit button
class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final habitProvider = context.read<HabitProvider>();
      habitProvider.initialize();
      habitProvider.refreshHabits();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.background,
      body: SafeArea(
        child: Consumer<HabitProvider>(
          builder: (context, habitProvider, _) {
            // Loading state
            if (habitProvider.isLoading && habitProvider.habits.isEmpty) {
              return const NoraLoading(message: 'Loading habits...');
            }

            // Error state
            if (habitProvider.error != null && habitProvider.habits.isEmpty) {
              return NoraError(
                message: habitProvider.error!,
                onRetry: () => habitProvider.refreshHabits(),
              );
            }

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
                              borderRadius:
                                  BorderRadius.circular(DesignTokens.radius12),
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
                                'Earn Screen Time',
                                style: TextStyle(
                                  color: DesignTokens.textPrimary,
                                  fontSize: DesignTokens.fontSizeH2,
                                  fontWeight: DesignTokens.fontWeightBold,
                                  fontFamily: DesignTokens.fontFamilyDisplay,
                                ),
                              ),
                              Text(
                                'Complete real-world habits to earn bonus minutes',
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

                // Today's earnings summary
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: DesignTokens.spacing20),
                    child: _buildEarningsSummary(habitProvider),
                  ),
                ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: DesignTokens.spacing24),
                ),

                // Habits list
                if (habitProvider.habits.isEmpty)
                  SliverToBoxAdapter(
                    child: _buildEmptyState(),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final habit = habitProvider.habits[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: DesignTokens.spacing20,
                              vertical: DesignTokens.spacing4),
                          child: _buildHabitCard(habit, habitProvider),
                        );
                      },
                      childCount: habitProvider.habits.length,
                    ),
                  ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: DesignTokens.spacing24),
                ),

                // Add habit button
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: DesignTokens.spacing20),
                    child: _buildAddHabitButton(),
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

  Widget _buildEarningsSummary(HabitProvider habitProvider) {
    return NoraCard(
      backgroundColor: DesignTokens.success.withValues(alpha: 0.06),
      border: Border.all(color: DesignTokens.success.withValues(alpha: 0.2)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: DesignTokens.success.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.add_circle_rounded,
              color: DesignTokens.success,
              size: 24,
            ),
          ),
          const SizedBox(width: DesignTokens.spacing16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Today\'s Earnings',
                  style: TextStyle(
                    color: DesignTokens.textPrimary,
                    fontSize: DesignTokens.fontSizeBody,
                    fontWeight: DesignTokens.fontWeightSemiBold,
                    fontFamily: DesignTokens.fontFamilyPrimary,
                  ),
                ),
                Text(
                  '${habitProvider.todayScreenTimeEarned} minutes earned from habits',
                  style: TextStyle(
                    color: DesignTokens.textMuted,
                    fontSize: DesignTokens.fontSizeCaption,
                    fontFamily: DesignTokens.fontFamilyPrimary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: DesignTokens.success,
              borderRadius: BorderRadius.circular(DesignTokens.radius20),
            ),
            child: Text(
              '+${habitProvider.todayScreenTimeEarned}m',
              style: TextStyle(
                color: Colors.white,
                fontSize: DesignTokens.fontSizeBody,
                fontWeight: DesignTokens.fontWeightBold,
                fontFamily: DesignTokens.fontFamilyPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(DesignTokens.spacing40),
      child: Column(
        children: [
          Icon(
            Icons.task_alt_rounded,
            color: DesignTokens.textMuted.withValues(alpha: 0.5),
            size: 64,
          ),
          const SizedBox(height: DesignTokens.spacing16),
          Text(
            'No habits yet',
            style: TextStyle(
              color: DesignTokens.textPrimary,
              fontSize: DesignTokens.fontSizeH3,
              fontWeight: DesignTokens.fontWeightSemiBold,
              fontFamily: DesignTokens.fontFamilyDisplay,
            ),
          ),
          const SizedBox(height: DesignTokens.spacing8),
          Text(
            'Create habits to earn screen time\nby completing real-world activities',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: DesignTokens.textMuted,
              fontSize: DesignTokens.fontSizeBodySmall,
              fontFamily: DesignTokens.fontFamilyPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHabitCard(Habit habit, HabitProvider habitProvider) {
    final isCompleted = habit.isCompletedToday;
    final color = Color(int.parse('FF${habit.color.substring(1)}', radix: 16));

    return GestureDetector(
      onTap: isCompleted
          ? null
          : () async {
              final earned = await habitProvider.completeHabit(habit.id);
              if (earned != null && mounted) {
                // Add bonus minutes to hard cap
                context.read<HardCapProvider>().addBonusMinutes(earned);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('+${earned}m screen time earned!'),
                    backgroundColor: DesignTokens.success,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(DesignTokens.radius12),
                    ),
                  ),
                );
              }
            },
      child: NoraCard(
        backgroundColor: isCompleted
            ? DesignTokens.success.withValues(alpha: 0.06)
            : null,
        border: isCompleted
            ? Border.all(color: DesignTokens.success.withValues(alpha: 0.2))
            : null,
        child: Row(
          children: [
            // Habit icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(DesignTokens.radius10),
              ),
              child: Icon(
                isCompleted ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: DesignTokens.spacing12),
            // Habit info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    habit.name,
                    style: TextStyle(
                      color: DesignTokens.textPrimary,
                      fontSize: DesignTokens.fontSizeBodySmall,
                      fontWeight: DesignTokens.fontWeightSemiBold,
                      fontFamily: DesignTokens.fontFamilyPrimary,
                      decoration: isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  Text(
                    '${habit.screenTimeMinutes}m screen time • ${habit.completionsToday}/${habit.targetPerDay} today',
                    style: TextStyle(
                      color: DesignTokens.textMuted,
                      fontSize: DesignTokens.fontSizeCaption,
                      fontFamily: DesignTokens.fontFamilyPrimary,
                    ),
                  ),
                ],
              ),
            ),
            // Status indicator
            if (isCompleted)
              Icon(
                Icons.check_circle_rounded,
                color: DesignTokens.success,
                size: 20,
              )
            else
              Icon(
                Icons.add_circle_outline_rounded,
                color: DesignTokens.textMuted,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddHabitButton() {
    return GestureDetector(
      onTap: _showAddHabitDialog,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: DesignTokens.surface,
          borderRadius: BorderRadius.circular(DesignTokens.radius12),
          border: Border.all(
            color: DesignTokens.accent.withValues(alpha: 0.3),
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_rounded,
              color: DesignTokens.accent,
              size: 20,
            ),
            const SizedBox(width: DesignTokens.spacing8),
            Text(
              'Add New Habit',
              style: TextStyle(
                color: DesignTokens.accent,
                fontSize: DesignTokens.fontSizeBodySmall,
                fontWeight: DesignTokens.fontWeightSemiBold,
                fontFamily: DesignTokens.fontFamilyPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddHabitDialog() {
    final nameController = TextEditingController();
    int screenTimeMinutes = 15;
    String selectedCategory = 'general';

    final categories = [
      {'key': 'exercise', 'label': 'Exercise', 'icon': Icons.fitness_center_rounded, 'color': '#FF5722'},
      {'key': 'reading', 'label': 'Reading', 'icon': Icons.menu_book_rounded, 'color': '#2196F3'},
      {'key': 'meditation', 'label': 'Meditation', 'icon': Icons.self_improvement_rounded, 'color': '#9C27B0'},
      {'key': 'outdoor', 'label': 'Outdoor', 'icon': Icons.park_rounded, 'color': '#4CAF50'},
      {'key': 'homework', 'label': 'Homework', 'icon': Icons.school_rounded, 'color': '#FF9800'},
      {'key': 'chores', 'label': 'Chores', 'icon': Icons.home_rounded, 'color': '#795548'},
      {'key': 'general', 'label': 'Other', 'icon': Icons.star_rounded, 'color': '#607D8B'},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: BoxDecoration(
              color: DesignTokens.background,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: DesignTokens.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Title
                Padding(
                  padding: const EdgeInsets.all(DesignTokens.spacing20),
                  child: Text(
                    'Add New Habit',
                    style: TextStyle(
                      color: DesignTokens.textPrimary,
                      fontSize: DesignTokens.fontSizeH3,
                      fontWeight: DesignTokens.fontWeightBold,
                      fontFamily: DesignTokens.fontFamilyDisplay,
                    ),
                  ),
                ),
                // Form
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: DesignTokens.spacing20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Habit name
                        Text(
                          'Habit Name',
                          style: TextStyle(
                            color: DesignTokens.textPrimary,
                            fontSize: DesignTokens.fontSizeBodySmall,
                            fontWeight: DesignTokens.fontWeightSemiBold,
                            fontFamily: DesignTokens.fontFamilyPrimary,
                          ),
                        ),
                        const SizedBox(height: DesignTokens.spacing8),
                        TextField(
                          controller: nameController,
                          style: TextStyle(
                            color: DesignTokens.textPrimary,
                            fontFamily: DesignTokens.fontFamilyPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText: 'e.g., Read for 30 minutes',
                            hintStyle: TextStyle(
                              color: DesignTokens.textMuted,
                              fontFamily: DesignTokens.fontFamilyPrimary,
                            ),
                            filled: true,
                            fillColor: DesignTokens.surface,
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(DesignTokens.radius12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: DesignTokens.spacing24),

                        // Category
                        Text(
                          'Category',
                          style: TextStyle(
                            color: DesignTokens.textPrimary,
                            fontSize: DesignTokens.fontSizeBodySmall,
                            fontWeight: DesignTokens.fontWeightSemiBold,
                            fontFamily: DesignTokens.fontFamilyPrimary,
                          ),
                        ),
                        const SizedBox(height: DesignTokens.spacing8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: categories.map((cat) {
                            final isSelected =
                                selectedCategory == cat['key'];
                            final catColor = Color(int.parse(
                                'FF${(cat['color'] as String).substring(1)}',
                                radix: 16));
                            return GestureDetector(
                              onTap: () => setModalState(
                                  () => selectedCategory = cat['key'] as String),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? catColor.withValues(alpha: 0.15)
                                      : DesignTokens.surface,
                                  borderRadius: BorderRadius.circular(
                                      DesignTokens.radius20),
                                  border: Border.all(
                                    color: isSelected
                                        ? catColor
                                        : DesignTokens.border,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      cat['icon'] as IconData,
                                      color: isSelected
                                          ? catColor
                                          : DesignTokens.textMuted,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      cat['label'] as String,
                                      style: TextStyle(
                                        color: isSelected
                                            ? catColor
                                            : DesignTokens.textMuted,
                                        fontSize: DesignTokens.fontSizeCaption,
                                        fontWeight: DesignTokens.fontWeightMedium,
                                        fontFamily: DesignTokens.fontFamilyPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: DesignTokens.spacing24),

                        // Screen time earned
                        Text(
                          'Screen Time Earned',
                          style: TextStyle(
                            color: DesignTokens.textPrimary,
                            fontSize: DesignTokens.fontSizeBodySmall,
                            fontWeight: DesignTokens.fontWeightSemiBold,
                            fontFamily: DesignTokens.fontFamilyPrimary,
                          ),
                        ),
                        const SizedBox(height: DesignTokens.spacing8),
                        Row(
                          children: [
                            Expanded(
                              child: SliderTheme(
                                data: SliderThemeData(
                                  activeTrackColor: DesignTokens.accent,
                                  inactiveTrackColor:
                                      DesignTokens.accent.withValues(alpha: 0.2),
                                  thumbColor: DesignTokens.accent,
                                  overlayColor:
                                      DesignTokens.accent.withValues(alpha: 0.1),
                                ),
                                child: Slider(
                                  value: screenTimeMinutes.toDouble(),
                                  min: 5,
                                  max: 60,
                                  divisions: 11,
                                  onChanged: (v) => setModalState(
                                      () => screenTimeMinutes = v.round()),
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: DesignTokens.accent.withValues(alpha: 0.15),
                                borderRadius:
                                    BorderRadius.circular(DesignTokens.radius8),
                              ),
                              child: Text(
                                '$screenTimeMinutes min',
                                style: TextStyle(
                                  color: DesignTokens.accent,
                                  fontSize: DesignTokens.fontSizeCaption,
                                  fontWeight: DesignTokens.fontWeightBold,
                                  fontFamily: DesignTokens.fontFamilyPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // Save button
                Padding(
                  padding: const EdgeInsets.all(DesignTokens.spacing20),
                  child: NoraButton(
                    label: 'Add Habit',
                    icon: Icons.add_rounded,
                    onPressed: nameController.text.isEmpty
                        ? null
                        : () async {
                            final navigator = Navigator.of(context);
                            final selectedCat = categories.firstWhere(
                                (c) => c['key'] == selectedCategory);
                            final success = await context
                                .read<HabitProvider>()
                                .createHabit(
                                  name: nameController.text,
                                  category: selectedCategory,
                                  icon:
                                      (selectedCat['icon'] as IconData).codePoint.toString(),
                                  color: selectedCat['color'] as String,
                                  screenTimeMinutes: screenTimeMinutes,
                                );
                            if (success) {
                              navigator.pop();
                            }
                          },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
