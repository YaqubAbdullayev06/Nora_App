import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/design_tokens.dart';
import '../../../core/theme/persona_theme.dart';
import '../../../providers/app_provider.dart';
import '../../../providers/plan_provider.dart';
import '../../../widgets/nora_components.dart';

/// Calendar Screen — month view showing task completion history.
/// Allows viewing past plans and tracking progress across days.
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _selectedMonth;
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime.now();
    _selectedDay = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AppProvider, PlanProvider>(
      builder: (context, app, plan, _) {
        final persona = app.persona;

        return Scaffold(
          backgroundColor: DesignTokens.background,
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(persona),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(DesignTokens.spacing20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildMonthNavigation(persona),
                        const SizedBox(height: DesignTokens.spacing20),
                        _buildCalendarGrid(persona, plan),
                        const SizedBox(height: DesignTokens.spacing24),
                        if (_selectedDay != null) ...[
                          _buildDaySummary(_selectedDay!, plan, persona),
                          const SizedBox(height: DesignTokens.spacing16),
                          _buildDayTasks(_selectedDay!, plan, persona),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(PersonaTheme persona) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacing20),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.arrow_back_ios_rounded,
              color: DesignTokens.textPrimary,
            ),
          ),
          const SizedBox(width: DesignTokens.spacing8),
          Text(
            'Calendar',
            style: TextStyle(
              color: DesignTokens.textPrimary,
              fontSize: DesignTokens.fontSizeH2,
              fontWeight: DesignTokens.fontWeightBold,
              fontFamily: DesignTokens.fontFamilyDisplay,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthNavigation(PersonaTheme persona) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: () {
            setState(() {
              _selectedMonth = DateTime(
                _selectedMonth.year,
                _selectedMonth.month - 1,
              );
            });
          },
          icon: Icon(
            Icons.chevron_left_rounded,
            color: DesignTokens.textPrimary,
          ),
        ),
        Text(
          '${months[_selectedMonth.month - 1]} ${_selectedMonth.year}',
          style: TextStyle(
            color: DesignTokens.textPrimary,
            fontSize: DesignTokens.fontSizeH3,
            fontWeight: DesignTokens.fontWeightSemiBold,
            fontFamily: DesignTokens.fontFamilyDisplay,
          ),
        ),
        IconButton(
          onPressed: () {
            setState(() {
              _selectedMonth = DateTime(
                _selectedMonth.year,
                _selectedMonth.month + 1,
              );
            });
          },
          icon: Icon(
            Icons.chevron_right_rounded,
            color: DesignTokens.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarGrid(PersonaTheme persona, PlanProvider plan) {
    final firstDay = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final lastDay = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
    final startWeekday = firstDay.weekday % 7; // Sunday = 0

    final days = <Widget>[];

    // Day headers
    final dayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    for (final label in dayLabels) {
      days.add(
        Center(
          child: Text(
            label,
            style: TextStyle(
              color: DesignTokens.textMuted,
              fontSize: DesignTokens.fontSizeCaption,
              fontWeight: DesignTokens.fontWeightMedium,
              fontFamily: DesignTokens.fontFamilyPrimary,
            ),
          ),
        ),
      );
    }

    // Empty cells before first day
    for (var i = 0; i < startWeekday; i++) {
      days.add(const SizedBox());
    }

    // Day cells
    for (var day = 1; day <= lastDay.day; day++) {
      final date = DateTime(_selectedMonth.year, _selectedMonth.month, day);
      final isToday = _isSameDay(date, DateTime.now());
      final isSelected = _selectedDay != null && _isSameDay(date, _selectedDay!);
      final isFuture = date.isAfter(DateTime.now());

      // Check if there's a plan for this day
      final hasPlan = plan.planHistory.any((p) => _isSameDay(p.date, date));
      final planForDay = plan.planHistory.where((p) => _isSameDay(p.date, date)).firstOrNull;

      double completionRate = 0;
      if (planForDay != null) {
        completionRate = planForDay.progress;
      }

      days.add(
        GestureDetector(
          onTap: isFuture ? null : () => setState(() => _selectedDay = date),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected
                  ? DesignTokens.accent
                  : isToday
                      ? DesignTokens.accent.withValues(alpha: 0.1)
                      : null,
              borderRadius: BorderRadius.circular(DesignTokens.radius8),
              border: isToday && !isSelected
                  ? Border.all(color: DesignTokens.accent.withValues(alpha: 0.3))
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$day',
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : isFuture
                            ? DesignTokens.textMuted.withValues(alpha: 0.5)
                            : DesignTokens.textPrimary,
                    fontSize: DesignTokens.fontSizeBody,
                    fontWeight: isToday ? DesignTokens.fontWeightBold : null,
                    fontFamily: DesignTokens.fontFamilyPrimary,
                  ),
                ),
                if (hasPlan && !isFuture) ...[
                  const SizedBox(height: 2),
                  Container(
                    width: 20,
                    height: 3,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.8)
                          : completionRate >= 0.8
                              ? DesignTokens.success
                              : completionRate > 0
                                  ? DesignTokens.warning
                                  : DesignTokens.textMuted.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 7,
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1,
      children: days,
    );
  }

  Widget _buildDaySummary(DateTime day, PlanProvider plan, PersonaTheme persona) {
    final planForDay = plan.planHistory.where((p) => _isSameDay(p.date, day)).firstOrNull;

    if (planForDay == null) {
      return NoraCard(
        child: Row(
          children: [
            Icon(
              Icons.event_note_rounded,
              color: DesignTokens.textMuted,
              size: 20,
            ),
            const SizedBox(width: DesignTokens.spacing12),
            Text(
              'No plan for this day',
              style: TextStyle(
                color: DesignTokens.textMuted,
                fontSize: DesignTokens.fontSizeBody,
                fontFamily: DesignTokens.fontFamilyPrimary,
              ),
            ),
          ],
        ),
      );
    }

    final completed = planForDay.completedCount;
    final total = planForDay.tasks.length;
    final points = planForDay.pointsEarned;

    return NoraCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem(
            '$completed/$total',
            'Tasks',
            Icons.check_circle_outline_rounded,
            DesignTokens.success,
          ),
          _buildSummaryItem(
            '$points',
            'Points',
            Icons.star_rounded,
            DesignTokens.warning,
          ),
          _buildSummaryItem(
            '${(planForDay.progress * 100).toInt()}%',
            'Progress',
            Icons.trending_up_rounded,
            DesignTokens.accent,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String value, String label, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: DesignTokens.spacing4),
        Text(
          value,
          style: TextStyle(
            color: DesignTokens.textPrimary,
            fontSize: DesignTokens.fontSizeBody,
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

  Widget _buildDayTasks(DateTime day, PlanProvider plan, PersonaTheme persona) {
    final planForDay = plan.planHistory.where((p) => _isSameDay(p.date, day)).firstOrNull;

    if (planForDay == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tasks',
          style: TextStyle(
            color: DesignTokens.textPrimary,
            fontSize: DesignTokens.fontSizeH3,
            fontWeight: DesignTokens.fontWeightSemiBold,
            fontFamily: DesignTokens.fontFamilyDisplay,
          ),
        ),
        const SizedBox(height: DesignTokens.spacing12),
        ...planForDay.tasks.map((task) => NoraCard(
              padding: const EdgeInsets.all(DesignTokens.spacing12),
              child: Row(
                children: [
                  Icon(
                    task.completed
                        ? Icons.check_circle_rounded
                        : Icons.circle_outlined,
                    color: task.completed
                        ? DesignTokens.success
                        : DesignTokens.textMuted,
                    size: 20,
                  ),
                  const SizedBox(width: DesignTokens.spacing12),
                  Expanded(
                    child: Text(
                      task.title,
                      style: TextStyle(
                        color: DesignTokens.textPrimary,
                        fontSize: DesignTokens.fontSizeBody,
                        fontFamily: DesignTokens.fontFamilyPrimary,
                        decoration: task.completed
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                  ),
                  Text(
                    task.priorityLabel,
                    style: TextStyle(
                      color: DesignTokens.textMuted,
                      fontSize: DesignTokens.fontSizeCaption,
                      fontFamily: DesignTokens.fontFamilyPrimary,
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
