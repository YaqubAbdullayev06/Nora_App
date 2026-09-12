import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/constants/design_tokens.dart';
import 'core/enums/age_group.dart';
import 'core/router/slide_route.dart';
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
import 'providers/persona_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/timer_provider.dart';
import 'providers/focus_provider.dart';
import 'providers/plan_provider.dart';
import 'providers/weekly_review_provider.dart';
import 'providers/agent_provider.dart';
import 'providers/focus_protection_provider.dart';
import 'services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  // Load auth tokens from secure storage before app starts
  await ApiService().init();

  runApp(const NoraApp());
}

class NoraApp extends StatelessWidget {
  const NoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Persona first — other providers depend on it
        ChangeNotifierProvider(
          create: (_) => PersonaProvider(initialAgeGroup: AgeGroup.adult),
        ),
        // Auth depends on Persona
        ChangeNotifierProvider(
          create: (ctx) => AuthProvider(
            personaProvider: ctx.read<PersonaProvider>(),
          ),
        ),
        // Timer depends on Persona
        ChangeNotifierProvider(
          create: (ctx) => TimerProvider(
            personaProvider: ctx.read<PersonaProvider>(),
          ),
        ),
        // Focus depends on Persona
        ChangeNotifierProvider(
          create: (ctx) => FocusProvider(
            personaProvider: ctx.read<PersonaProvider>(),
          ),
        ),
        // Plan depends on Persona
        ChangeNotifierProvider(
          create: (ctx) => PlanProvider(
            personaProvider: ctx.read<PersonaProvider>(),
          ),
        ),
        // WeeklyReview depends on Persona + Focus
        ChangeNotifierProvider(
          create: (ctx) => WeeklyReviewProvider(
            personaProvider: ctx.read<PersonaProvider>(),
            focusProvider: ctx.read<FocusProvider>(),
          ),
        ),
        // Agent (standalone)
        ChangeNotifierProvider(create: (_) => AgentProvider()),
        // Focus protection (standalone)
        ChangeNotifierProvider(create: (_) => FocusProtectionProvider()),
        // Legacy provider for backward compatibility
        ChangeNotifierProvider(create: (_) => AppProvider()..init()),
        ChangeNotifierProvider(create: (_) => BreathingProvider()),
      ],
      child: Consumer<PersonaProvider>(
        builder: (context, personaProvider, _) {
          // Update DesignTokens when persona changes
          DesignTokens.init(personaProvider.persona);

          return MaterialApp(
            title: 'Nora',
            debugShowCheckedModeBanner: false,
            theme: personaProvider.persona.toThemeData(),
            initialRoute: '/',
            builder: (context, child) {
              final isLocked = context.select<AuthProvider, bool>(
                (auth) => auth.isAppLocked,
              );
              if (isLocked) {
                return const AppLockScreen();
              }
              return child ?? const SizedBox.shrink();
            },
            onGenerateRoute: (settings) {
              // Splash screen — no transition (first screen)
              if (settings.name == '/') {
                return PageRouteBuilder(
                  settings: settings,
                  pageBuilder: (_, __, ___) => const SplashScreen(),
                  transitionsBuilder: (_, __, ___, child) => child,
                  transitionDuration: Duration.zero,
                );
              }

              Widget page;
              switch (settings.name) {
                case '/welcome':
                  page = const WelcomeScreen();
                  break;
                case '/onboarding':
                  page = const OnboardingScreen();
                  break;
                case '/login':
                  page = const LoginScreen();
                  break;
                case '/register':
                  final ageGroup = settings.arguments as AgeGroup?;
                  page = RegisterScreen(ageGroup: ageGroup);
                  break;
                case '/main':
                  page = const MainScreen();
                  break;
                case '/chat':
                  page = const ChatScreen();
                  break;
                case '/assistant':
                  page = const AssistantScreen();
                  break;
                case '/app-scan':
                  page = const AppScanScreen();
                  break;
                case '/weekly-review':
                  page = const WeeklyReviewScreen();
                  break;
                case '/timer':
                  page = const TimerScreen();
                  break;
                default:
                  return null;
              }

              return FadePageRoute(
                settings: settings,
                pageBuilder: (_, __, ___) => page,
              );
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

  /// Lazy-built screens — each screen is only constructed when first visited.
  final Map<int, Widget> _screenCache = {};

  Widget _buildScreen(int index) {
    return _screenCache.putIfAbsent(index, () {
      switch (index) {
        case 0:
          return HomeScreen(onPlanTap: () => setState(() => _currentIndex = 5));
        case 1:
          return const BreathingScreen();
        case 2:
          return const TimerScreen();
        case 3:
          return const StatsScreen();
        case 4:
          return const ProfileScreen();
        case 5:
          return const PlanScreen();
        default:
          return const HomeScreen();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeIn,
        switchOutCurve: Curves.easeOut,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
          child: KeyedSubtree(
            key: ValueKey(_currentIndex),
            child: _buildScreen(_currentIndex),
          ),
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
