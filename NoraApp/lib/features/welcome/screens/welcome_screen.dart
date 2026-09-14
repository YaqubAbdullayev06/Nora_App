import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/design_tokens.dart';
import '../../../core/theme/persona_theme.dart';
import '../../../providers/app_provider.dart';
import '../../../widgets/nora_components.dart';

/// Welcome Screen — introduces Nora before asking for customization.
///
/// This is the first interactive screen new users see after the splash.
/// It explains what Nora is, shows key features, and lets the user
/// proceed to personalization at their own pace.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;
  int _currentPage = 0;

  static const _pages = _WelcomeData.pages;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      setState(() => _currentPage++);
      _controller.reset();
      _controller.forward();
    } else {
      // Last page → go to onboarding (age + name)
      Navigator.pushReplacementNamed(context, '/onboarding');
    }
  }

  void _skip() {
    Navigator.pushReplacementNamed(context, '/onboarding');
  }

  @override
  Widget build(BuildContext context) {
    final persona = context.watch<AppProvider>().persona;
    final page = _pages[_currentPage];
    final isLast = _currentPage == _pages.length - 1;

    return Scaffold(
      backgroundColor: DesignTokens.background,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 8, 20, 0),
                child: !isLast
                    ? GestureDetector(
                        onTap: _skip,
                        child: Text(
                          'Skip',
                          style: TextStyle(
                            color: DesignTokens.textMuted,
                            fontSize: DesignTokens.fontSizeBodySmall,
                            fontFamily: DesignTokens.fontFamilyPrimary,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),

            // Page content
            Expanded(
              child: FadeTransition(
                opacity: _fadeIn,
                child: SlideTransition(
                  position: _slideUp,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: DesignTokens.spacing24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Mascot / Icon
                        _buildHero(page, persona),
                        const SizedBox(height: DesignTokens.spacing32),

                        // Title
                        Text(
                          page.title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: DesignTokens.textPrimary,
                            fontSize: DesignTokens.fontSizeH1,
                            fontWeight: DesignTokens.fontWeightBold,
                            fontFamily: DesignTokens.fontFamilyDisplay,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: DesignTokens.spacing12),

                        // Subtitle
                        Text(
                          page.subtitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: DesignTokens.textMuted,
                            fontSize: DesignTokens.fontSizeBody,
                            fontFamily: DesignTokens.fontFamilyPrimary,
                            height: 1.5,
                          ),
                        ),

                        // Optional feature list
                        if (page.features != null) ...[
                          const SizedBox(height: DesignTokens.spacing24),
                          ...page.features!.map((f) => Padding(
                                padding: const EdgeInsets.only(
                                    bottom: DesignTokens.spacing10),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: persona.primary
                                            .withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        f.icon,
                                        color: persona.primary,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(
                                        width: DesignTokens.spacing12),
                                    Expanded(
                                      child: Text(
                                        f.label,
                                        style: TextStyle(
                                          color: DesignTokens.textPrimary,
                                          fontSize:
                                              DesignTokens.fontSizeBodySmall,
                                          fontFamily:
                                              DesignTokens.fontFamilyPrimary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Bottom: page indicator + button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                children: [
                  // Page dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == i ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == i
                              ? persona.primary
                              : DesignTokens.textMuted.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: DesignTokens.spacing20),

                  // Get Started / Continue button
                  SizedBox(
                    height: 56,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: persona.primary,
                        foregroundColor:
                            persona.isDark ? DesignTokens.background : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(DesignTokens.radius20),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        isLast ? 'Get Started' : 'Continue',
                        style: TextStyle(
                          fontSize: DesignTokens.fontSizeBody,
                          fontWeight: DesignTokens.fontWeightSemiBold,
                          fontFamily: DesignTokens.fontFamilyPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: DesignTokens.spacing16),

                  // Sign in link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: TextStyle(
                          color: DesignTokens.textMuted,
                          fontSize: DesignTokens.fontSizeBodySmall,
                          fontFamily: DesignTokens.fontFamilyPrimary,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pushReplacementNamed(context, '/login'),
                        child: Text(
                          'Sign In',
                          style: TextStyle(
                            color: persona.primary,
                            fontSize: DesignTokens.fontSizeBodySmall,
                            fontWeight: DesignTokens.fontWeightSemiBold,
                            fontFamily: DesignTokens.fontFamilyPrimary,
                          ),
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
    );
  }

  Widget _buildHero(_PageData page, PersonaTheme persona) {
    // Prefer SVG asset if provided
    if (page.assetPath != null) {
      return Container(
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [persona.primary, persona.secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: persona.primary.withValues(alpha: 0.4),
              blurRadius: 40,
              spreadRadius: 8,
            ),
          ],
        ),
        child: Center(
          child: SvgPicture.asset(
            page.assetPath!,
            width: 80,
            height: 80,
            fit: BoxFit.contain,
          ),
        ),
      );
    }

    // Fallback: mascot
    return NoraMascot(size: 140, showGlow: true);
  }
}

// ─── Data Models ───

class _FeatureItem {
  final IconData icon;
  final String label;
  const _FeatureItem(this.icon, this.label);
}

class _PageData {
  final String title;
  final String subtitle;
  final String? assetPath;
  final List<_FeatureItem>? features;

  const _PageData({
    required this.title,
    required this.subtitle,
    this.assetPath,
    this.features,
  });
}

class _WelcomeData {
  const _WelcomeData._();

  static const pages = [
    _PageData(
      title: 'Meet Nora',
      subtitle:
          'Your personal AI assistant that adapts to you. Nora learns your style, respects your focus, and grows with you.',
      assetPath: 'assets/images/mascots/adult_brain.svg',
      features: [
        _FeatureItem(Icons.psychology_rounded, 'Adapts to your age and style'),
        _FeatureItem(Icons.shield_rounded, 'Privacy-first with parental controls'),
        _FeatureItem(Icons.auto_awesome_rounded, 'Powered by advanced AI'),
      ],
    ),
    _PageData(
      title: 'Focus & Grow',
      subtitle:
          'Build focus habits with smart timers, track your progress, and unlock achievements along the way.',
      assetPath: 'assets/images/mascots/nora_rocket.svg',
      features: [
        _FeatureItem(Icons.timer_rounded, 'Smart focus sessions with breaks'),
        _FeatureItem(Icons.bar_chart_rounded, 'Track streaks and milestones'),
        _FeatureItem(Icons.emoji_events_rounded, 'Earn rewards for consistency'),
      ],
    ),
    _PageData(
      title: 'Your Space',
      subtitle:
          'Nora adapts her personality, content, and interface to match who\'s using the app. Let\'s set things up for you.',
      assetPath: 'assets/images/mascots/nora_owl.svg',
      features: [
        _FeatureItem(Icons.palette_rounded, 'Themes that match your vibe'),
        _FeatureItem(Icons.school_rounded, 'Content curated for your level'),
        _FeatureItem(Icons.person_rounded, 'Your profile, your rules'),
      ],
    ),
  ];
}
