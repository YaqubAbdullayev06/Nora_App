import 'package:flutter/material.dart';
import '../../../core/constants/design_tokens.dart';
import '../../../providers/app_provider.dart';
import '../../../widgets/nora_components.dart';

/// Hero actions — prominent scanner card + one-tap focus button + secondary actions.
class HomeActions extends StatelessWidget {
  final AppProvider provider;
  final VoidCallback? onPlanTap;

  const HomeActions({
    super.key,
    required this.provider,
    this.onPlanTap,
  });

  @override
  Widget build(BuildContext context) {
    final persona = provider.persona;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── HERO: App Scanner card (full width, prominent) ──
        _HeroScannerCard(
          gradient: [persona.primary, persona.secondary],
          onTap: () => Navigator.pushNamed(context, '/app-scan'),
        ),
        const SizedBox(height: DesignTokens.spacing12),

        // ── One-tap Focus button ──
        _FocusButton(
          accentColor: persona.primary,
          onTap: () => Navigator.pushNamed(context, '/timer'),
        ),
        const SizedBox(height: DesignTokens.spacing16),

        // ── Secondary actions row ──
        SectionHeader(
          title: "More",
          icon: Icons.grid_view_rounded,
          iconColor: DesignTokens.textMuted,
        ),
        const SizedBox(height: DesignTokens.spacing12),
        Row(
          children: [
            Expanded(
              child: _ActionCard(
                iconAsset: 'assets/images/icons/ai_brain.svg',
                title: 'AI Chat',
                subtitle: 'Ask Nora anything',
                color: persona.primary,
                onTap: () => Navigator.pushNamed(context, '/chat'),
              ),
            ),
            const SizedBox(width: DesignTokens.spacing12),
            Expanded(
              child: _ActionCard(
                iconAsset: 'assets/images/icons/calendar.svg',
                title: 'Weekly Review',
                subtitle: 'Reflect & set goals',
                color: DesignTokens.accentSecondary,
                onTap: () => Navigator.pushNamed(context, '/weekly-review'),
              ),
            ),
          ],
        ),
        const SizedBox(height: DesignTokens.spacing12),
        Row(
          children: [
            Expanded(
              child: _ActionCard(
                iconAsset: 'assets/images/icons/clipboard-list.svg',
                title: 'Daily Plan',
                subtitle: 'Structure your day',
                color: DesignTokens.success,
                onTap: onPlanTap ?? () {},
              ),
            ),
            const SizedBox(width: DesignTokens.spacing12),
            Expanded(
              child: _ActionCard(
                iconAsset: 'assets/images/icons/clipboard-list.svg',
                title: 'App Timer',
                subtitle: 'Set daily app limits',
                color: DesignTokens.warning,
                onTap: () => Navigator.pushNamed(context, '/app-timer-limits'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Hero Scanner Card ───

class _HeroScannerCard extends StatelessWidget {
  final List<Color> gradient;
  final VoidCallback onTap;

  const _HeroScannerCard({required this.gradient, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(DesignTokens.radius20),
          boxShadow: [
            BoxShadow(
              color: gradient.first.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(DesignTokens.radius14),
              ),
              child: const Center(
                child: Icon(Icons.phonelink_erase_rounded, color: Colors.white, size: 28),
              ),
            ),
            const SizedBox(width: 16),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Scan & Block Apps',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: DesignTokens.fontSizeH2,
                      fontWeight: DesignTokens.fontWeightBold,
                      fontFamily: DesignTokens.fontFamilyDisplay,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Find what\'s stealing your time and block it in one tap.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: DesignTokens.fontSizeCaption,
                      fontFamily: DesignTokens.fontFamilyPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white.withValues(alpha: 0.6), size: 18),
          ],
        ),
      ),
    );
  }
}

// ─── One-tap Focus Button ───

class _FocusButton extends StatelessWidget {
  final Color accentColor;
  final VoidCallback onTap;

  const _FocusButton({required this.accentColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: DesignTokens.surface,
          borderRadius: BorderRadius.circular(DesignTokens.radius16),
          border: Border.all(color: accentColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.play_arrow_rounded, color: accentColor, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Start Focus Mode',
                    style: TextStyle(
                      color: DesignTokens.textPrimary,
                      fontSize: DesignTokens.fontSizeBody,
                      fontWeight: DesignTokens.fontWeightSemiBold,
                      fontFamily: DesignTokens.fontFamilyPrimary,
                    ),
                  ),
                  Text(
                    'Block distractions & start a focus session',
                    style: TextStyle(
                      color: DesignTokens.textMuted,
                      fontSize: DesignTokens.fontSizeCaption,
                      fontFamily: DesignTokens.fontFamilyPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.timer_outlined, color: accentColor, size: 22),
          ],
        ),
      ),
    );
  }
}

// ─── Secondary Action Card ───

class _ActionCard extends StatefulWidget {
  final String iconAsset;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.iconAsset,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  State<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<_ActionCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: NoraCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: NoraIcon(
                    assetPath: widget.iconAsset,
                    size: 20,
                    color: widget.color,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                widget.title,
                style: TextStyle(
                  color: DesignTokens.textPrimary,
                  fontSize: DesignTokens.fontSizeBodySmall,
                  fontWeight: DesignTokens.fontWeightSemiBold,
                  fontFamily: DesignTokens.fontFamilyPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                widget.subtitle,
                style: TextStyle(
                  color: DesignTokens.textMuted,
                  fontSize: DesignTokens.fontSizeCaption,
                  fontFamily: DesignTokens.fontFamilyPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
