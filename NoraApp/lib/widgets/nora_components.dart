import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../core/constants/design_tokens.dart';
import '../core/theme/persona_theme.dart';
import 'loader_one.dart';

export 'loader_one.dart';

/// Reusable Card component — adapts to current PersonaTheme.
/// Background, border, radius all come from DesignTokens (which reads from persona).
/// Set [glass] to true for glassmorphism effect (blur + translucent tint).
class NoraCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? radius;
  final Color? backgroundColor;
  final List<BoxShadow>? boxShadow;
  final Border? border;
  final Gradient? gradient;
  final VoidCallback? onTap;
  final bool glass;
  final double glassOpacity;
  final double glassBlur;

  const NoraCard({
    super.key,
    required this.child,
    this.padding,
    this.radius,
    this.backgroundColor,
    this.boxShadow,
    this.border,
    this.gradient,
    this.onTap,
    this.glass = false,
    this.glassOpacity = 0.85,
    this.glassBlur = 20,
  });

  @override
  State<NoraCard> createState() => _NoraCardState();
}

class _NoraCardState extends State<NoraCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = widget.radius ?? DesignTokens.cardRadius;

    final cardContent = Container(
      padding: widget.padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.gradient == null
            ? (widget.backgroundColor ?? DesignTokens.surface)
            : null,
        gradient: widget.gradient,
        borderRadius: BorderRadius.circular(effectiveRadius),
        border: widget.border ??
            Border.all(
              color: widget.glass
                  ? Colors.white.withValues(alpha: 0.08)
                  : DesignTokens.border,
              width: widget.glass ? 1 : DesignTokens.cardBorderWidth,
            ),
        boxShadow: widget.boxShadow ??
            [
              BoxShadow(
                color: widget.glass
                    ? Colors.black.withValues(alpha: 0.15)
                    : DesignTokens.textPrimary.withValues(alpha: 0.08),
                blurRadius: widget.glass ? 20 : 10,
                offset: widget.glass
                    ? const Offset(0, 8)
                    : const Offset(0, 2),
              ),
            ],
      ),
      child: widget.child,
    );

    Widget result = widget.glass
        ? ClipRRect(
            borderRadius: BorderRadius.circular(effectiveRadius),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: widget.glassBlur,
                sigmaY: widget.glassBlur,
              ),
              child: Container(
                padding: widget.padding ?? const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: (widget.backgroundColor ?? DesignTokens.surface)
                      .withValues(alpha: widget.glassOpacity),
                  borderRadius: BorderRadius.circular(effectiveRadius),
                  border: widget.border ??
                      Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                        width: 1,
                      ),
                  boxShadow: widget.boxShadow ??
                      [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                ),
                child: widget.child,
              ),
            ),
          )
        : cardContent;

    if (widget.onTap == null) return result;

    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isPressed ? 0.98 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: result,
        ),
      ),
    );
  }
}

/// Stats Card — label muted, value colored, adapts to persona.
/// Set [glass] to true for glassmorphism effect.
class StatsCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool glass;

  const StatsCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.glass = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: $value',
      child: NoraCard(
        glass: glass,
        backgroundColor: glass ? color.withValues(alpha: 0.15) : null,
        padding: glass ? const EdgeInsets.all(14) : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            if (glass) const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: DesignTokens.fontSizeH3,
                fontWeight: DesignTokens.fontWeightBold,
                fontFamily: DesignTokens.fontFamilyPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: DesignTokens.textMuted,
                fontSize: DesignTokens.fontSizeCaption,
                fontFamily: DesignTokens.fontFamilyPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Badge / Chip — adapts to persona colors.
class NoraBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final bool outlined;

  NoraBadge({
    super.key,
    required this.label,
    Color? color,
    this.icon,
    this.outlined = false,
  }) : color = color ?? DesignTokens.accent;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: outlined ? Colors.transparent : color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(999),
          border: outlined ? Border.all(color: color, width: 1) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: DesignTokens.fontSizeCaption,
                fontWeight: DesignTokens.fontWeightMedium,
                fontFamily: DesignTokens.fontFamilyPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Primary Button — adapts to persona colors and radius with tactile press bounce.
class NoraButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool outlined;
  final bool expanded;
  final double? height;
  final Color? color;
  final Color? textColor;
  final Gradient? gradient;

  const NoraButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.outlined = false,
    this.expanded = false,
    this.height,
    this.color,
    this.textColor,
    this.gradient,
  });

  @override
  State<NoraButton> createState() => _NoraButtonState();
}

class _NoraButtonState extends State<NoraButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.color ?? DesignTokens.accent;
    final fgColor = widget.textColor ?? (widget.outlined ? activeColor : DesignTokens.background);

    final btn = Container(
      height: widget.height ?? DesignTokens.buttonHeight,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: widget.outlined
            ? Colors.transparent
            : (widget.gradient == null ? activeColor : null),
        gradient: widget.outlined ? null : widget.gradient,
        borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
        border: widget.outlined
            ? Border.all(color: activeColor, width: 1.5)
            : null,
        boxShadow: widget.outlined
            ? null
            : [
                BoxShadow(
                  color: activeColor.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Row(
        mainAxisSize: widget.expanded ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.icon != null) ...[
            Icon(widget.icon, color: fgColor, size: 20),
            const SizedBox(width: 8),
          ],
          Text(
            widget.label,
            style: TextStyle(
              color: fgColor,
              fontSize: DesignTokens.fontSizeBodySmall,
              fontWeight: DesignTokens.fontWeightBold,
              fontFamily: DesignTokens.fontFamilyPrimary,
            ),
          ),
        ],
      ),
    );

    return Semantics(
      button: true,
      enabled: widget.onPressed != null,
      label: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: widget.onPressed == null ? null : (_) => setState(() => _isPressed = true),
        onTapUp: widget.onPressed == null ? null : (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onPressed,
        child: AnimatedScale(
          scale: _isPressed ? 0.95 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: btn,
        ),
      ),
    );
  }
}

/// Rich Cover Image Card with gradient scrim, badge, and tags
class NoraImageCard extends StatelessWidget {
  final String? imageUrl;
  final String title;
  final String subtitle;
  final String category;
  final int durationMinutes;
  final int points;
  final IconData? typeIcon;
  final VoidCallback? onTap;

  const NoraImageCard({
    super.key,
    this.imageUrl,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.durationMinutes,
    required this.points,
    this.typeIcon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label: '$title, $category, $durationMinutes minutes',
      child: NoraCard(
        padding: EdgeInsets.zero,
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Image section with gradient overlay
            Stack(
              children: [
                Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: DesignTokens.surfaceRaised,
                    gradient: LinearGradient(
                      colors: [
                        DesignTokens.accent.withValues(alpha: 0.3),
                        DesignTokens.accentSecondary.withValues(alpha: 0.3),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: imageUrl != null && imageUrl!.isNotEmpty
                      ? Image.network(
                          imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Center(
                            child: Icon(
                              typeIcon ?? Icons.auto_stories_rounded,
                              size: 48,
                              color: DesignTokens.accent.withValues(alpha: 0.6),
                            ),
                          ),
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(DesignTokens.accent),
                              ),
                            );
                          },
                        )
                      : Center(
                          child: Icon(
                            typeIcon ?? Icons.auto_stories_rounded,
                            size: 48,
                            color: DesignTokens.accent.withValues(alpha: 0.6),
                          ),
                        ),
                ),
                // Gradient scrim on top of image
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          DesignTokens.surface.withValues(alpha: 0.9),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
                // Top-left Category Pill
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white24, width: 0.8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (typeIcon != null) ...[
                          Icon(typeIcon, color: Colors.white, size: 12),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          category,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: DesignTokens.fontSizeExtraSmall,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Top-right XP reward badge
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: DesignTokens.warning.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded, color: Colors.black, size: 14),
                        const SizedBox(width: 2),
                        Text(
                          '+$points XP',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: DesignTokens.fontSizeExtraSmall,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Text info section
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: DesignTokens.textPrimary,
                      fontSize: DesignTokens.fontSizeBody,
                      fontWeight: DesignTokens.fontWeightBold,
                      fontFamily: DesignTokens.fontFamilyDisplay,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: DesignTokens.textMuted,
                      fontSize: DesignTokens.fontSizeSmall,
                      height: 1.3,
                      fontFamily: DesignTokens.fontFamilyPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.schedule_rounded, size: 14, color: DesignTokens.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        '$durationMinutes min read',
                        style: TextStyle(
                          color: DesignTokens.textMuted,
                          fontSize: DesignTokens.fontSizeCaption,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Read & Quiz →',
                        style: TextStyle(
                          color: DesignTokens.accent,
                          fontSize: DesignTokens.fontSizeCaption,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}

/// Section Header — title with optional icon.
class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final IconData? icon;
  final Color? iconColor;

  const SectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: (iconColor ?? DesignTokens.accent).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor ?? DesignTokens.accent, size: 16),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              title,
              style: TextStyle(
                color: DesignTokens.textPrimary,
                fontSize: DesignTokens.fontSizeH3,
                fontWeight: DesignTokens.fontWeightSemiBold,
                fontFamily: DesignTokens.fontFamilyDisplay,
              ),
            ),
          ],
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// Nora Mascot — the AI companion character.
/// Shows SVG mascot image with emoji fallback.
class NoraMascot extends StatelessWidget {
  final double size;
  final bool showGlow;
  final PersonaTheme? personaOverride;

  const NoraMascot({
    super.key,
    this.size = 80,
    this.showGlow = true,
    this.personaOverride,
  });

  @override
  Widget build(BuildContext context) {
    final persona = personaOverride ?? DesignTokens.current;
    final hasAsset = persona.mascotAssetPath != null;

    return Semantics(
      label: '${persona.mascotName} mascot',
      image: true,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [persona.primary, persona.secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: showGlow
              ? [
                  BoxShadow(
                    color: persona.primary.withValues(alpha: 0.4),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                ]
              : null,
        ),
        child: ClipOval(
          child: SvgPicture.asset(
            persona.mascotAssetPath,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}

/// Age Group Badge — shows current persona.
class AgeGroupBadge extends StatelessWidget {
  const AgeGroupBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final persona = DesignTokens.current;
    return NoraBadge(
      label: persona.mascotName,
      icon: Icons.person_rounded,
      color: persona.primary,
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// DAILY PLANNING WIDGETS
// ═══════════════════════════════════════════════════════════════

/// A circular progress indicator showing X/Y tasks completed.
class PlanProgressRing extends StatelessWidget {
  final int completed;
  final int total;
  final double size;

  const PlanProgressRing({
    super.key,
    required this.completed,
    required this.total,
    this.size = 64,
  });

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? completed / total : 0.0;
    final persona = DesignTokens.current;

    return Semantics(
      label: '$completed of $total tasks completed',
      value: '${(progress * 100).round()}%',
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background circle
            SizedBox(
              width: size,
              height: size,
              child: CircularProgressIndicator(
                value: 1.0,
                strokeWidth: 6,
                valueColor: AlwaysStoppedAnimation<Color>(
                  DesignTokens.border,
                ),
              ),
            ),
            // Progress circle
            SizedBox(
              width: size,
              height: size,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 6,
                strokeCap: StrokeCap.round,
                valueColor: AlwaysStoppedAnimation<Color>(
                  completed == total && total > 0
                      ? DesignTokens.success
                      : persona.primary,
                ),
              ),
            ),
            // Center text
            Text(
              '$completed/$total',
              style: TextStyle(
                color: DesignTokens.textPrimary,
                fontSize: size * 0.22,
                fontWeight: DesignTokens.fontWeightBold,
                fontFamily: DesignTokens.fontFamilyPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single task card with checkbox, priority indicator, and title.
/// Set [glass] to true for glassmorphism effect.
class PlanTaskCard extends StatefulWidget {
  final dynamic task; // PlanTask from models.dart
  final VoidCallback? onToggle;
  final bool interactive;
  final bool glass;
  final Color? accentColor;

  const PlanTaskCard({
    super.key,
    required this.task,
    this.onToggle,
    this.interactive = true,
    this.glass = false,
    this.accentColor,
  });

  @override
  State<PlanTaskCard> createState() => _PlanTaskCardState();
}

class _PlanTaskCardState extends State<PlanTaskCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late AnimationController _checkController;
  late Animation<double> _checkScale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _checkController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
      value: widget.task.completed ? 1.0 : 0.0,
    );
    _checkScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _checkController, curve: Curves.elasticOut),
    );
  }

  @override
  void didUpdateWidget(PlanTaskCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.task.completed && !oldWidget.task.completed) {
      _checkController.forward();
    } else if (!widget.task.completed && oldWidget.task.completed) {
      _checkController.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _checkController.dispose();
    super.dispose();
  }

  Color _getPriorityColor() {
    switch (widget.task.priority) {
      case 1:
        return DesignTokens.danger;
      case 2:
        return DesignTokens.warning;
      case 3:
        return DesignTokens.success;
      default:
        return DesignTokens.accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = widget.task.completed;
    final priorityColor = widget.accentColor ?? _getPriorityColor();

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Semantics(
            button: true,
            label: '${widget.task.title}, priority ${widget.task.priorityLabel}${isCompleted ? ", completed" : ""}',
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTapDown: widget.interactive ? (_) => _controller.forward() : null,
        onTapUp: widget.interactive
            ? (_) {
                _controller.reverse();
                if (!isCompleted) {
                  HapticFeedback.mediumImpact();
                } else {
                  HapticFeedback.lightImpact();
                }
                widget.onToggle?.call();
              }
            : null,
        onTapCancel: widget.interactive ? () => _controller.reverse() : null,
        child: NoraCard(
          glass: widget.glass,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          backgroundColor: isCompleted
              ? DesignTokens.success.withValues(alpha: 0.08)
              : null,
          border: Border.all(
            color: isCompleted
                ? DesignTokens.success.withValues(alpha: 0.3)
                : widget.glass
                    ? Colors.white.withValues(alpha: 0.08)
                    : DesignTokens.border,
            width: 1,
          ),
          child: Row(
            children: [
              // Priority indicator
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  color: priorityColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              // Checkbox
              GestureDetector(
                onTap: widget.interactive
                    ? () {
                        HapticFeedback.selectionClick();
                        widget.onToggle?.call();
                      }
                    : null,
                child: AnimatedBuilder(
                  animation: _checkScale,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _checkScale.value,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCompleted
                              ? priorityColor
                              : Colors.transparent,
                          border: Border.all(
                            color: isCompleted
                                ? priorityColor
                                : DesignTokens.textMuted,
                            width: 2,
                          ),
                        ),
                        child: isCompleted
                            ? const Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 16,
                              )
                            : null,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              // Title
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.task.title,
                      style: TextStyle(
                        color: isCompleted
                            ? DesignTokens.textMuted
                            : DesignTokens.textPrimary,
                        fontSize: DesignTokens.fontSizeBody,
                        fontWeight: DesignTokens.fontWeightMedium,
                        fontFamily: DesignTokens.fontFamilyPrimary,
                        decoration: isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                        decorationColor: DesignTokens.textMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.task.priorityLabel,
                      style: TextStyle(
                        color: priorityColor,
                        fontSize: DesignTokens.fontSizeCaption,
                        fontWeight: DesignTokens.fontWeightMedium,
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
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ICON COMPONENT
// ═══════════════════════════════════════════════════════════════

/// SVG icon wrapper — replaces emoji text throughout the app.
/// Shows an SVG asset with optional colored background circle.
/// Falls back to an IconData if the SVG fails to load.
class NoraIcon extends StatelessWidget {
  final String assetPath;
  final double size;
  final Color? color;
  final Color? backgroundColor;
  final IconData fallbackIcon;
  final double? bgSize;

  const NoraIcon({
    super.key,
    required this.assetPath,
    this.size = 20,
    this.color,
    this.backgroundColor,
    this.fallbackIcon = Icons.circle,
    this.bgSize,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = color ?? DesignTokens.textPrimary;
    final effectiveBgSize = bgSize ?? (size + 12);

    final iconWidget = SvgPicture.asset(
      assetPath,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
      placeholderBuilder: (context) => Icon(
        fallbackIcon,
        size: size,
        color: iconColor,
      ),
    );

    if (backgroundColor == null) return iconWidget;

    return Container(
      width: effectiveBgSize,
      height: effectiveBgSize,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
      ),
      child: Center(child: iconWidget),
    );
  }
}

/// Gradient stat card for horizontal scroll — large number, SVG icon, label.
class StatCardHorizontal extends StatelessWidget {
  final String label;
  final String value;
  final String iconAsset;
  final Color color;

  const StatCardHorizontal({
    super.key,
    required this.label,
    required this.value,
    required this.iconAsset,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: $value',
      child: NoraCard(
        backgroundColor: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NoraIcon(
            assetPath: iconAsset,
            size: 20,
            color: color,
            backgroundColor: color.withValues(alpha: 0.15),
            bgSize: 36,
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: DesignTokens.fontSizeH1,
              fontWeight: DesignTokens.fontWeightBold,
              fontFamily: DesignTokens.fontFamilyDisplay,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: DesignTokens.textMuted,
              fontSize: DesignTokens.fontSizeCaption,
              fontFamily: DesignTokens.fontFamilyPrimary,
            ),
          ),
        ],
      ),
    ),
    );
  }
}

/// Action card — icon + title + subtitle + chevron, with optional glass effect.
class NoraActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final bool glass;

  const NoraActionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.onTap,
    this.glass = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label: '$title: $subtitle',
      child: NoraCard(
        glass: glass,
        onTap: onTap,
        backgroundColor: glass ? color.withValues(alpha: 0.1) : null,
        padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 22, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeBodySmall,
                    fontWeight: DesignTokens.fontWeightSemiBold,
                    color: DesignTokens.textPrimary,
                    fontFamily: DesignTokens.fontFamilyPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeCaption,
                    color: DesignTokens.textMuted,
                    fontFamily: DesignTokens.fontFamilyPrimary,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            size: 18,
            color: DesignTokens.textMuted,
          ),
        ],
      ),
    ),
    );
  }
}

/// Morning planning prompt card with mascot and input fields.
class PlanPromptCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String mascotAsset;

  const PlanPromptCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.mascotAsset,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$title: $subtitle',
      child: NoraCard(
        gradient: LinearGradient(
        colors: [
          DesignTokens.accent.withValues(alpha: 0.15),
          DesignTokens.accentSecondary.withValues(alpha: 0.15),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Column(
        children: [
          // Mascot
          SizedBox(
            width: 80,
            height: 80,
            child: SvgPicture.asset(
              mascotAsset,
              fit: BoxFit.contain,
              placeholderBuilder: (context) => Center(
                child: Icon(
                  Icons.star_rounded,
                  size: 48,
                  color: DesignTokens.accent.withValues(alpha: 0.6),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Title
          Text(
            title,
            style: TextStyle(
              color: DesignTokens.textPrimary,
              fontSize: DesignTokens.fontSizeH2,
              fontWeight: DesignTokens.fontWeightBold,
              fontFamily: DesignTokens.fontFamilyDisplay,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          // Subtitle
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
    ),
    );
  }
}
