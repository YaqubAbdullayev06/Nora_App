import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/constants/design_tokens.dart';
import 'core/enums/age_group.dart';
import 'features/welcome/screens/welcome_screen.dart';
import 'features/onboarding/screens/onboarding_screen.dart';
import 'features/splash/screens/splash_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'features/breathing/screens/breathing_screen.dart';
import 'features/breathing/providers/breathing_provider.dart';
import 'features/timer/screens/timer_screen.dart';
import 'features/stats/screens/stats_screen.dart';
import 'features/profile/screens/profile_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/chat/screens/chat_screen.dart';
import 'features/chat/screens/assistant_screen.dart';
import 'features/scan/screens/app_scan_screen.dart';
import 'features/access/screens/app_lock_screen.dart';
import 'features/weekly_review/screens/weekly_review_screen.dart';
import 'features/plan/screens/plan_screen.dart';
import 'providers/app_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const NoraApp());
}

class NoraApp extends StatelessWidget {
  const NoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()..init()),
        ChangeNotifierProvider(create: (_) => BreathingProvider()),
      ],
      child: Consumer<AppProvider>(
        builder: (context, provider, _) {
          // Update DesignTokens when persona changes
          DesignTokens.init(provider.persona);

          return MaterialApp(
            title: 'Nora',
            debugShowCheckedModeBanner: false,
            theme: provider.persona.toThemeData(),
            initialRoute: '/',
            builder: (context, child) {
              if (provider.isAppLocked) {
                return const AppLockScreen();
              }
              return child ?? const SizedBox.shrink();
            },
            routes: {
              '/': (context) => const SplashScreen(),
              '/welcome': (context) => const WelcomeScreen(),
              '/onboarding': (context) => const OnboardingScreen(),
              '/login': (context) => const LoginScreen(),
              '/register': (context) {
                final ageGroup = ModalRoute.of(context)?.settings.arguments as AgeGroup?;
                return RegisterScreen(ageGroup: ageGroup);
              },
              '/main': (context) => const MainScreen(),
              '/chat': (context) => const ChatScreen(),
              '/assistant': (context) => const AssistantScreen(),
              '/app-scan': (context) => const AppScanScreen(),
              '/weekly-review': (context) => const WeeklyReviewScreen(),
              '/timer': (context) => const TimerScreen(),
            },
          );
        },
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreen(onPlanTap: () => setState(() => _currentIndex = 5)),
      const BreathingScreen(),
      const TimerScreen(),
      const StatsScreen(),
      const ProfileScreen(),
      const PlanScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: DesignTokens.surfaceRaised.withValues(alpha: 0.95),
          boxShadow: [
            BoxShadow(
              color: DesignTokens.accent.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_rounded, 'Home'),
                _buildNavItem(1, Icons.air_rounded, 'Breathe'),
                _buildNavItem(2, Icons.timer_rounded, 'Timer'),
                _buildCenterButton(),
                _buildNavItem(3, Icons.analytics_rounded, 'Stats'),
                _buildNavItem(4, Icons.person_rounded, 'Profile'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCenterButton() {
    final isSelected = _currentIndex == 5;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = 5),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? DesignTokens.accent.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(DesignTokens.radius20),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // Animated big circle overlay — scales in/out on selection
            AnimatedScale(
              scale: isSelected ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: AnimatedOpacity(
                opacity: isSelected ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [DesignTokens.accent, DesignTokens.accentSecondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: DesignTokens.accent.withValues(alpha: 0.4),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Icon + Label — always same size as other nav items
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_month_rounded,
                  color: isSelected ? Colors.white : DesignTokens.textMuted,
                  size: isSelected ? 26 : 22,
                ),
                const SizedBox(height: 4),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    color: isSelected ? Colors.white : DesignTokens.textMuted,
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                  child: const Text('Plan'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? DesignTokens.accent.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(DesignTokens.radius20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? DesignTokens.accent : DesignTokens.textMuted,
              size: isSelected ? 26 : 22,
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                color: isSelected ? DesignTokens.accent : DesignTokens.textMuted,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
