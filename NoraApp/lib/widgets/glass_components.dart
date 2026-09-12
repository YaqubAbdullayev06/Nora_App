import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/design_tokens.dart';

/// GlassCard — Glassmorphism card with blur + translucency.
///
/// DESIGN SPEC:
/// - Background: Translucent Midnight (#141927 at 85% opacity)
/// - BackdropFilter: blur(20)
/// - Border: 1px white at 10% opacity
/// - Shadow: subtle glow matching accent color
///
/// Usage: Replace NoraCard with GlassCard for premium glass effect.
class GlassCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final Color? tintColor;
  final double opacity;
  final double blurAmount;
  final VoidCallback? onTap;
  final bool enableHaptics;
  final Border? border;
  final List<BoxShadow>? boxShadow;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.tintColor,
    this.opacity = 0.85,
    this.blurAmount = 20,
    this.onTap,
    this.enableHaptics = true,
    this.border,
    this.boxShadow,
  });

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? DesignTokens.cardRadius;
    final tintColor = widget.tintColor ?? DesignTokens.surface;

    final card = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: widget.blurAmount,
          sigmaY: widget.blurAmount,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          transform: Matrix4.identity()..scale(_isPressed ? 0.98 : 1.0),
          padding: widget.padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: tintColor.withOpacity(widget.opacity),
            borderRadius: BorderRadius.circular(radius),
            border: widget.border ?? Border.all(
              color: Colors.white.withOpacity(0.08),
              width: 1,
            ),
            boxShadow: widget.boxShadow ?? [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: widget.child,
        ),
      ),
    );

    if (widget.onTap == null) return card;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () {
        if (widget.enableHaptics) {
          HapticFeedback.lightImpact();
        }
        widget.onTap?.call();
      },
      child: card,
    );
  }
}

/// GlassStatsCard — Stats card with glassmorphism.
class GlassStatsCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const GlassStatsCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      tintColor: color.withOpacity(0.15),
      opacity: 0.7,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: DesignTokens.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: DesignTokens.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

/// GlassActionCard — Action button card with glassmorphism.
class GlassActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const GlassActionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      tintColor: color.withOpacity(0.1),
      opacity: 0.7,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
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
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: DesignTokens.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: DesignTokens.textMuted,
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
    );
  }
}

/// GlassTaskCard — Task item card with glassmorphism + haptic checkbox.
class GlassTaskCard extends StatefulWidget {
  final String title;
  final bool isCompleted;
  final Color accentColor;
  final VoidCallback? onToggle;
  final VoidCallback? onTap;

  const GlassTaskCard({
    super.key,
    required this.title,
    this.isCompleted = false,
    this.accentColor = const Color(0xFF00C896),
    this.onToggle,
    this.onTap,
  });

  @override
  State<GlassTaskCard> createState() => _GlassTaskCardState();
}

class _GlassTaskCardState extends State<GlassTaskCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _checkController;
  late Animation<double> _checkScale;

  @override
  void initState() {
    super.initState();
    _checkController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
      value: widget.isCompleted ? 1.0 : 0.0,
    );
    _checkScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _checkController, curve: Curves.elasticOut),
    );
  }

  @override
  void didUpdateWidget(GlassTaskCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCompleted && !oldWidget.isCompleted) {
      _checkController.forward();
      HapticFeedback.mediumImpact();
    } else if (!widget.isCompleted && oldWidget.isCompleted) {
      _checkController.reverse();
    }
  }

  @override
  void dispose() {
    _checkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: widget.onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          // Checkbox
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              widget.onToggle?.call();
            },
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
                      color: widget.isCompleted
                          ? widget.accentColor
                          : Colors.transparent,
                      border: Border.all(
                        color: widget.isCompleted
                            ? widget.accentColor
                            : DesignTokens.textMuted.withOpacity(0.4),
                        width: 2,
                      ),
                    ),
                    child: widget.isCompleted
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : null,
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          // Title
          Expanded(
            child: Text(
              widget.title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: widget.isCompleted
                    ? DesignTokens.textMuted
                    : DesignTokens.textPrimary,
                decoration: widget.isCompleted
                    ? TextDecoration.lineThrough
                    : null,
                decorationColor: DesignTokens.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
