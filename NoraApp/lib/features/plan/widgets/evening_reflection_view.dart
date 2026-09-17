import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/constants/design_tokens.dart';
import '../../../core/enums/age_group.dart';
import '../../../providers/app_provider.dart';
import '../../../widgets/nora_components.dart';

class EveningReflectionView extends StatefulWidget {
  final AppProvider provider;
  final AgeGroup ageGroup;

  const EveningReflectionView({
    super.key,
    required this.provider,
    required this.ageGroup,
  });

  @override
  State<EveningReflectionView> createState() => _EveningReflectionViewState();
}

class _EveningReflectionViewState extends State<EveningReflectionView> {
  final TextEditingController _reflectionController = TextEditingController();

  @override
  void dispose() {
    _reflectionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.ageGroup.reflectionLabel,
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
              _buildDaySummary(),
              const SizedBox(height: 24),
              _buildReflectionInput(),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: NoraButton(
                  label: 'Save Reflection',
                  icon: Icons.check_rounded,
                  expanded: true,
                  onPressed: _submitReflection,
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDaySummary() {
    return NoraCard(
      child: Column(
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: SvgPicture.asset(
              widget.ageGroup.planMascotAsset,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem(
                Icons.check_circle_rounded,
                '${widget.provider.completedTasksToday}/${widget.provider.totalTasksToday}',
                'Tasks',
                DesignTokens.success,
              ),
              _buildStatItem(
                Icons.star_rounded,
                '${widget.provider.pointsEarnedToday}',
                'Points',
                DesignTokens.warning,
              ),
              _buildStatItem(
                Icons.local_fire_department_rounded,
                '${widget.provider.streakDays}',
                'Streak',
                DesignTokens.danger,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label, Color color) {
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

  Widget _buildReflectionInput() {
    String hint;
    int maxLines;

    switch (widget.ageGroup) {
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
                colorFilter: ColorFilter.mode(DesignTokens.accent, BlendMode.srcIn),
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

  void _submitReflection() {
    final note = _reflectionController.text.trim();
    widget.provider.submitReflection(note);
    _reflectionController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Reflection saved! Great job today.',
          style: TextStyle(fontFamily: DesignTokens.fontFamilyPrimary),
        ),
        backgroundColor: DesignTokens.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
