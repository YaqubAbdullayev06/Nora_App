import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../../providers/app_provider.dart';
import '../../../widgets/loader_one.dart';
import '../../../widgets/animated_text.dart';

/// Splash Screen — animated brand introduction.
/// Adapts its colors and mascot based on the current persona.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.7, curve: Curves.easeIn),
      ),
    );

    _controller.forward();

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/welcome');
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final persona = provider.persona;

        return Scaffold(
          backgroundColor: persona.background,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _scaleAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [persona.primary, persona.secondary],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: persona.primary.withValues(alpha: 0.5),
                              blurRadius: 40,
                              spreadRadius: 8,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: SvgPicture.asset(
                            persona.mascotAssetPath,
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),
                AnimatedText(
                  text: 'Nora',
                  style: TextStyle(
                    color: persona.primary,
                    fontSize: 48,
                    fontWeight: FontWeight.w700,
                    fontFamily: persona.fontFamily,
                    letterSpacing: 2,
                  ),
                  animationType: AnimatedTextType.letters,
                  duration: const Duration(milliseconds: 800),
                  staggerDelay: const Duration(milliseconds: 100),
                ),
                const SizedBox(height: 8),
                AnimatedText(
                  text: persona.tagline,
                  style: TextStyle(
                    color: persona.textMuted,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    fontFamily: persona.fontFamily,
                  ),
                  animationType: AnimatedTextType.words,
                  delay: const Duration(milliseconds: 500),
                  duration: const Duration(milliseconds: 500),
                  staggerDelay: const Duration(milliseconds: 80),
                ),
                const SizedBox(height: 48),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: LoaderOne(
                    color: persona.primary,
                    dotSize: 10,
                    spacing: 6,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
