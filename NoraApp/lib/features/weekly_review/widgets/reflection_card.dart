import 'package:flutter/material.dart';
import '../../../core/constants/design_tokens.dart';
import '../../../widgets/nora_components.dart';
import '../../../models/models.dart';

/// Reflection Card for Weekly Review.
/// Displays a reflection question and answer, or allows entering a new one.
class ReflectionCard extends StatefulWidget {
  final String question;
  final String? existingAnswer;
  final ValueChanged<String> onAnswerSubmitted;

  const ReflectionCard({
    super.key,
    required this.question,
    this.existingAnswer,
    required this.onAnswerSubmitted,
  });

  @override
  State<ReflectionCard> createState() => _ReflectionCardState();
}

class _ReflectionCardState extends State<ReflectionCard> {
  late TextEditingController _controller;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.existingAnswer ?? '');
    _isEditing = widget.existingAnswer == null || widget.existingAnswer!.isEmpty;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NoraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: DesignTokens.accentTertiary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(DesignTokens.radius8),
                ),
                child: Icon(
                  Icons.help_outline_rounded,
                  color: DesignTokens.accentTertiary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.question,
                  style: TextStyle(
                    color: DesignTokens.textPrimary,
                    fontSize: DesignTokens.fontSizeBody,
                    fontWeight: DesignTokens.fontWeightSemiBold,
                    fontFamily: DesignTokens.fontFamilyPrimary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Answer area
          if (_isEditing)
            _buildEditingArea()
          else
            _buildDisplayArea(),
        ],
      ),
    );
  }

  Widget _buildEditingArea() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: DesignTokens.surfaceRaised,
            borderRadius: BorderRadius.circular(DesignTokens.radius12),
            border: Border.all(
              color: DesignTokens.accentTertiary.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: TextField(
            controller: _controller,
            maxLines: 3,
            minLines: 2,
            style: TextStyle(
              color: DesignTokens.textPrimary,
              fontSize: DesignTokens.fontSizeBodySmall,
              fontFamily: DesignTokens.fontFamilyPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Type your reflection here...',
              hintStyle: TextStyle(
                color: DesignTokens.textMuted,
                fontSize: DesignTokens.fontSizeBodySmall,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            NoraButton(
              label: 'Save',
              icon: Icons.check_rounded,
              onPressed: _controller.text.trim().isNotEmpty
                  ? () {
                      setState(() => _isEditing = false);
                      widget.onAnswerSubmitted(_controller.text.trim());
                    }
                  : null,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDisplayArea() {
    return GestureDetector(
      onTap: () => setState(() => _isEditing = true),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: DesignTokens.surfaceRaised,
          borderRadius: BorderRadius.circular(DesignTokens.radius12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                widget.existingAnswer ?? '',
                style: TextStyle(
                  color: DesignTokens.textPrimary,
                  fontSize: DesignTokens.fontSizeBodySmall,
                  fontFamily: DesignTokens.fontFamilyPrimary,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.edit_rounded,
              color: DesignTokens.textMuted,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}