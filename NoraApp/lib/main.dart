import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'core/constants/design_tokens.dart';
import 'core/enums/age_group.dart';
import 'core/router/slide_route.dart';
import 'features/welcome/screens/welcome_screen.dart';
import 'features/onboarding/screens/onboarding_screen.dart';
import 'features/splash/screens/splash_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'features/timer/screens/timer_screen.dart';
import 'features/breathing/providers/breathing_provider.dart';
import 'features/stats/screens/stats_screen.dart';
import 'features/stats/screens/screen_time_screen.dart';
import 'features/profile/screens/profile_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/chat/screens/assistant_screen.dart';
import 'features/scan/screens/app_scan_screen.dart';
import 'features/access/screens/app_lock_screen.dart';
import 'features/access/screens/app_timer_limits_screen.dart';
import 'features/accountability/screens/accountability_setup_screen.dart';
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
import 'providers/app_timer_provider.dart';
import 'providers/accountability_provider.dart';
import 'providers/hard_cap_provider.dart';
import 'providers/pomodoro_provider.dart';
import 'providers/habit_provider.dart';
import 'features/hardcap/screens/hard_cap_setup_screen.dart';
import 'features/hardcap/widgets/hard_cap_overlay.dart';
import 'features/pomodoro/screens/pomodoro_setup_screen.dart';
import 'features/habits/screens/habits_screen.dart';
import 'services/api_service.dart';
import 'services/connectivity_service.dart';
import 'widgets/connectivity_banner.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  // Load auth tokens BEFORE runApp so providers can use them immediately
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
        // App timer limits (standalone) — initialized lazily after first frame
        ChangeNotifierProvider(create: (_) => AppTimerProvider()),
        // Accountability lock — session-scoped, initialized lazily
        ChangeNotifierProvider(create: (_) => AccountabilityProvider()),
        // Hard cap — session-scoped, initialized lazily
        ChangeNotifierProvider(create: (_) => HardCapProvider()),
        // Pomodoro multi-cycle — session-scoped, initialized lazily
        ChangeNotifierProvider(create: (_) => PomodoroProvider()),
        // Habit tracking — session-scoped, initialized lazily
        ChangeNotifierProvider(create: (_) => HabitProvider()),
        // Connectivity monitoring — starts checking immediately
        ChangeNotifierProvider(create: (_) => ConnectivityService()..startChecking()),
        // Legacy provider for backward compatibility — initialized lazily after first frame
        ChangeNotifierProvider(create: (_) => AppProvider()),
        ChangeNotifierProvider(create: (_) => BreathingProvider()),
      ],
      child: Consumer<PersonaProvider>(
        builder: (context, personaProvider, _) {
          // Update DesignTokens when persona changes
          DesignTokens.init(personaProvider.persona);

          // Reset accountability session state on each app start
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<AccountabilityProvider>().resetSession();
          });

          return MaterialApp(
            title: 'Nora',
            debugShowCheckedModeBanner: false,
            theme: personaProvider.persona.toThemeData(),
            initialRoute: '/',
            builder: (context, child) {
              final isLocked = context.select<AuthProvider, bool>(
                (auth) => auth.isAppLocked,
              );
              final result = isLocked
                  ? const AppLockScreen()
                  : Column(
                      children: [
                        const ConnectivityBanner(),
                        Expanded(
                          child: HardCapOverlay(
                            child: child ?? const SizedBox.shrink(),
                          ),
                        ),
                      ],
                    );
              // Clamp system text scale to prevent UI overflow
              final mediaQuery = MediaQuery.of(context);
              final clampedScale = mediaQuery.textScaler.clamp(
                minScaleFactor: 0.8,
                maxScaleFactor: 2.0,
              );
              return MediaQuery(
                data: mediaQuery.copyWith(textScaler: clampedScale),
                child: result,
              );
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
                  page = const AssistantScreen();
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
                case '/app-timer-limits':
                  page = const AppTimerLimitsScreen();
                  break;
                case '/accountability-setup':
                  page = const AccountabilitySetupScreen();
                  break;
                case '/hard-cap-setup':
                  page = const HardCapSetupScreen();
                  break;
                case '/pomodoro-setup':
                  page = const PomodoroSetupScreen();
                  break;
                case '/habits':
                  page = const HabitsScreen();
                  break;
                case '/timer':
                  page = const TimerScreen();
                  break;
                case '/screen-time':
                  page = const ScreenTimeScreen();
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
          return HomeScreen(onPlanTap: () => setState(() => _currentIndex = 4));
        case 1:
          return const TimerScreen();
        case 2:
          return const StatsScreen();
        case 3:
          return const ProfileScreen();
        case 4:
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
                _buildNavItem(0, 'assets/images/icons/home.svg', 'Home'),
                _buildNavItem(1, 'assets/images/icons/timer.svg', 'Timer'),
                _buildCenterButton(),
                _buildNavItem(2, 'assets/images/icons/stats.svg', 'Stats'),
                _buildNavItem(3, 'assets/images/icons/user.svg', 'Profile'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCenterButton() {
    final isSelected = _currentIndex == 4;
    return Semantics(
      button: true,
      selected: isSelected,
      label: 'Plan',
      child: GestureDetector(
        onTap: () => setState(() => _currentIndex = 4),
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
                SvgPicture.asset(
                  'assets/images/icons/calendar-check.svg',
                  width: isSelected ? 26 : 22,
                  height: isSelected ? 26 : 22,
                  colorFilter: ColorFilter.mode(
                    isSelected ? Colors.white : DesignTokens.textMuted,
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    color: isSelected ? Colors.white : DesignTokens.textMuted,
                    fontSize: DesignTokens.fontSizeTiny,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                  child: const Text('Plan'),
                ),
              ],
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, String assetPath, String label) {
    final isSelected = _currentIndex == index;
    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: GestureDetector(
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
            SvgPicture.asset(
              assetPath,
              width: isSelected ? 26 : 22,
              height: isSelected ? 26 : 22,
              colorFilter: ColorFilter.mode(
                isSelected ? DesignTokens.accent : DesignTokens.textMuted,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                color: isSelected ? DesignTokens.accent : DesignTokens.textMuted,
                fontSize: DesignTokens.fontSizeTiny,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              child: Text(label),
            ),
          ],
        ),
        ),
      ),
    );
  }
}
