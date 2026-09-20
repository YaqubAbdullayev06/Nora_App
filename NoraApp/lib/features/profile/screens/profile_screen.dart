import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/design_tokens.dart';
import '../../../core/enums/age_group.dart';
import '../../../core/theme/persona_theme.dart';
import '../../../providers/persona_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/focus_provider.dart';
import '../../../providers/accountability_provider.dart';
import '../../../providers/hard_cap_provider.dart';
import '../../../providers/pomodoro_provider.dart';
import '../../../providers/habit_provider.dart';
import '../../../widgets/nora_components.dart';
import '../utils/age_group_helpers.dart';
import '../widgets/profile_dialogs.dart';
import '../../accountability/screens/accountability_setup_screen.dart';
import '../../plan/screens/calendar_screen.dart';

/// Profile Screen — age-adaptive settings and user info.
/// Baby: Parent controls, simple UI
/// Kid: Achievement display, parental settings
/// Teen: Social features, preferences
/// Adult: Full settings, export data, account management
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer3<PersonaProvider, AuthProvider, FocusProvider>(
      builder: (context, personaProvider, authProvider, focusProvider, _) {
        final persona = personaProvider.persona;

        return Scaffold(
          backgroundColor: DesignTokens.background,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(DesignTokens.spacing20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, personaProvider, authProvider, persona),
                  const SizedBox(height: DesignTokens.spacing24),
                  _buildPersonaCard(persona),
                  const SizedBox(height: DesignTokens.spacing24),
                  _buildQuickStats(focusProvider, persona),
                  const SizedBox(height: DesignTokens.spacing24),
                  _buildSettingsSection(context, personaProvider, authProvider, persona),
                  const SizedBox(height: DesignTokens.spacing24),
                  _buildAccountSection(context, authProvider, persona),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(
      BuildContext context, PersonaProvider personaProvider, AuthProvider authProvider, PersonaTheme persona) {
    return Row(
      children: [
        const NoraMascot(size: 80, showGlow: true),
        const SizedBox(width: DesignTokens.spacing16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                authProvider.currentUser?.name ?? 'Explorer',
                style: TextStyle(
                  color: DesignTokens.textPrimary,
                  fontSize: DesignTokens.fontSizeH2,
                  fontWeight: DesignTokens.fontWeightBold,
                  fontFamily: DesignTokens.fontFamilyDisplay,
                ),
              ),
              Text(
                authProvider.currentUser?.email ?? 'explorer@nora.app',
                style: TextStyle(
                  color: DesignTokens.textMuted,
                  fontSize: DesignTokens.fontSizeBodySmall,
                  fontFamily: DesignTokens.fontFamilyPrimary,
                ),
              ),
              const SizedBox(height: DesignTokens.spacing4),
              const AgeGroupBadge(),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => showEditProfileSheet(context, authProvider),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: DesignTokens.surface,
              borderRadius: BorderRadius.circular(DesignTokens.radius12),
              border: Border.all(color: DesignTokens.border, width: 1),
            ),
            child: Icon(
              Icons.edit_rounded,
              color: DesignTokens.textMuted,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPersonaCard(PersonaTheme persona) {
    return NoraCard(
      backgroundColor: persona.primary.withValues(alpha: 0.1),
      border:
          Border.all(color: persona.primary.withValues(alpha: 0.3), width: 1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SvgPicture.asset(
                persona.mascotAssetPath,
                width: 32,
                height: 32,
              ),
              const SizedBox(width: DesignTokens.spacing12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nora as ${persona.mascotName}',
                      style: TextStyle(
                        color: persona.primary,
                        fontSize: DesignTokens.fontSizeBody,
                        fontWeight: DesignTokens.fontWeightSemiBold,
                        fontFamily: DesignTokens.fontFamilyPrimary,
                      ),
                    ),
                    Text(
                      persona.tagline,
                      style: TextStyle(
                        color: DesignTokens.textMuted,
                        fontSize: DesignTokens.fontSizeCaption,
                        fontFamily: DesignTokens.fontFamilyPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spacing12),
          _buildPersonaFeatures(persona),
        ],
      ),
    );
  }

  Widget _buildPersonaFeatures(PersonaTheme persona) {
    final features = persona.ageGroup.features;
    return Wrap(
      spacing: DesignTokens.spacing8,
      runSpacing: DesignTokens.spacing8,
      children: features.map((feature) {
        return NoraBadge(
          label: feature['label']!,
          icon: persona.ageGroup.featureIcon(feature['icon']!),
          color: persona.primary,
        );
      }).toList(),
    );
  }

  Widget _buildQuickStats(FocusProvider provider, PersonaTheme persona) {
    return Row(
      children: [
        Expanded(
          child: StatsCard(
            label: persona.ageGroup.scoreLabel,
            value: '${provider.focusScore}',
            icon: Icons.star_rounded,
            color: DesignTokens.accent,
          ),
        ),
        const SizedBox(width: DesignTokens.spacing12),
        Expanded(
          child: StatsCard(
            label: persona.ageGroup.streakLabel,
            value: '${provider.streakDays}',
            icon: Icons.local_fire_department_rounded,
            color: DesignTokens.warning,
          ),
        ),
        const SizedBox(width: DesignTokens.spacing12),
        Expanded(
          child: StatsCard(
            label: persona.ageGroup.sessionsLabel,
            value: '${provider.sessionsCompleted}',
            icon: Icons.check_circle_rounded,
            color: DesignTokens.success,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsSection(
      BuildContext context, PersonaProvider personaProvider, AuthProvider authProvider, PersonaTheme persona) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: persona.ageGroup.settingsTitle,
          icon: Icons.settings_rounded,
          iconColor: DesignTokens.textMuted,
        ),
        const SizedBox(height: DesignTokens.spacing12),
        _buildSettingsTile(
          icon: Icons.person_rounded,
          title: 'Edit Profile',
          subtitle: persona.ageGroup.editProfileSubtitle,
          onTap: () => showEditProfileSheet(context, authProvider),
        ),
        _buildSettingsTile(
          icon: Icons.notifications_rounded,
          title: 'Notifications',
          subtitle: persona.ageGroup.notificationSubtitle,
          onTap: () => showNotificationsDialog(context, authProvider),
        ),
        _buildSettingsTile(
          icon: Icons.shield_rounded,
          title: 'Focus protection',
          subtitle: 'Choose permissions to block distracting apps',
          onTap: () => showFocusProtectionDialog(context, personaProvider),
        ),
        _buildAccountabilityTile(context, persona),
        _buildHardCapTile(context, persona),
        _buildPomodoroTile(context, persona),
        _buildHabitsTile(context, persona),
        _buildCalendarTile(context, persona),
        _buildSettingsTile(
          icon: Icons.auto_awesome_rounded,
          title: 'Nora capabilities',
          subtitle: 'View the skills available to your AI assistant',
          onTap: () => showAgentCapabilitiesDialog(context, personaProvider),
        ),
        if (persona.ageGroup == AgeGroup.adult) ...[
          _buildSettingsTile(
            icon: Icons.download_rounded,
            title: 'Export Data',
            subtitle: 'Download your focus history',
            onTap: () {},
          ),
          _buildSettingsTile(
            icon: Icons.palette_rounded,
            title: 'Switch Persona',
            subtitle: 'Change age group (for testing)',
            onTap: () => showPersonaSwitcher(context, personaProvider),
          ),
        ],
        if (persona.ageGroup.requiresParentalControl) ...[
          _buildSettingsTile(
            icon: Icons.shield_rounded,
            title: 'Parent Controls',
            subtitle: 'Manage screen time and content',
            onTap: () {},
          ),
        ],
      ],
    );
  }

  Widget _buildAccountabilityTile(BuildContext context, PersonaTheme persona) {
    return Consumer<AccountabilityProvider>(
      builder: (context, accountability, _) {
        final isActive = accountability.isLockActive;
        final guardianName = accountability.guardianName;

        return GestureDetector(
          onTap: () {
            if (isActive) {
              // Show unlink dialog
              _showUnlinkDialog(context, accountability);
            } else {
              // Navigate to setup
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AccountabilitySetupScreen(),
                ),
              );
            }
          },
          child: NoraCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (isActive ? Colors.green : DesignTokens.accent)
                        .withValues(alpha: 0.15),
                    borderRadius:
                        BorderRadius.circular(DesignTokens.radius10),
                  ),
                  child: Icon(
                    isActive ? Icons.lock_rounded : Icons.lock_open_rounded,
                    color: isActive ? Colors.green : DesignTokens.accent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: DesignTokens.spacing12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Accountability Lock',
                        style: TextStyle(
                          color: DesignTokens.textPrimary,
                          fontSize: DesignTokens.fontSizeBodySmall,
                          fontWeight: DesignTokens.fontWeightSemiBold,
                          fontFamily: DesignTokens.fontFamilyPrimary,
                        ),
                      ),
                      Text(
                        isActive
                            ? 'Active — set by ${guardianName ?? "guardian"}'
                            : 'Guardian PIN lock for focus sessions',
                        style: TextStyle(
                          color: DesignTokens.textMuted,
                          fontSize: DesignTokens.fontSizeCaption,
                          fontFamily: DesignTokens.fontFamilyPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: DesignTokens.textMuted, size: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHardCapTile(BuildContext context, PersonaTheme persona) {
    return Consumer<HardCapProvider>(
      builder: (context, cap, _) {
        final isActive = cap.isActive;
        final remaining = cap.remainingMinutes;
        final usage = cap.todayUsageMinutes;

        return GestureDetector(
          onTap: () {
            Navigator.pushNamed(context, '/hard-cap-setup');
          },
          child: NoraCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (isActive ? Colors.orange : DesignTokens.accent)
                        .withValues(alpha: 0.15),
                    borderRadius:
                        BorderRadius.circular(DesignTokens.radius10),
                  ),
                  child: Icon(
                    isActive
                        ? Icons.timer_rounded
                        : Icons.timer,
                    color: isActive ? Colors.orange : DesignTokens.accent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: DesignTokens.spacing12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Daily Hard Cap',
                        style: TextStyle(
                          color: DesignTokens.textPrimary,
                          fontSize: DesignTokens.fontSizeBodySmall,
                          fontWeight: DesignTokens.fontWeightSemiBold,
                          fontFamily: DesignTokens.fontFamilyPrimary,
                        ),
                      ),
                      Text(
                        isActive
                            ? '$usage / ${cap.capMinutes} min today — ${remaining > 0 ? "${remaining}m left" : "Over limit"}'
                            : 'Set a total daily screen time limit',
                        style: TextStyle(
                          color: DesignTokens.textMuted,
                          fontSize: DesignTokens.fontSizeCaption,
                          fontFamily: DesignTokens.fontFamilyPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: DesignTokens.textMuted, size: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPomodoroTile(BuildContext context, PersonaTheme persona) {
    return Consumer<PomodoroProvider>(
      builder: (context, pomodoro, _) {
        final isEnabled = pomodoro.autoCycleEnabled;
        final completed = pomodoro.completedCycles;
        final target = pomodoro.targetCycles;

        return GestureDetector(
          onTap: () {
            Navigator.pushNamed(context, '/pomodoro-setup');
          },
          child: NoraCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (isEnabled ? Colors.purple : DesignTokens.accent)
                        .withValues(alpha: 0.15),
                    borderRadius:
                        BorderRadius.circular(DesignTokens.radius10),
                  ),
                  child: Icon(
                    isEnabled ? Icons.repeat_rounded : Icons.repeat_one_rounded,
                    color: isEnabled ? Colors.purple : DesignTokens.accent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: DesignTokens.spacing12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pomodoro Cycles',
                        style: TextStyle(
                          color: DesignTokens.textPrimary,
                          fontSize: DesignTokens.fontSizeBodySmall,
                          fontWeight: DesignTokens.fontWeightSemiBold,
                          fontFamily: DesignTokens.fontFamilyPrimary,
                        ),
                      ),
                      Text(
                        isEnabled
                            ? 'Auto-cycle: $completed/$target cycles today'
                            : 'Chain focus sessions automatically',
                        style: TextStyle(
                          color: DesignTokens.textMuted,
                          fontSize: DesignTokens.fontSizeCaption,
                          fontFamily: DesignTokens.fontFamilyPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: DesignTokens.textMuted, size: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHabitsTile(BuildContext context, PersonaTheme persona) {
    return Consumer<HabitProvider>(
      builder: (context, habitProvider, _) {
        final todayEarned = habitProvider.todayScreenTimeEarned;
        final completedCount = habitProvider.completedHabits.length;
        final totalCount = habitProvider.habits.length;

        return GestureDetector(
          onTap: () {
            Navigator.pushNamed(context, '/habits');
          },
          child: NoraCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (todayEarned > 0
                            ? DesignTokens.success
                            : DesignTokens.accent)
                        .withValues(alpha: 0.15),
                    borderRadius:
                        BorderRadius.circular(DesignTokens.radius10),
                  ),
                  child: Icon(
                    todayEarned > 0
                        ? Icons.check_circle_rounded
                        : Icons.task_alt_rounded,
                    color: todayEarned > 0
                        ? DesignTokens.success
                        : DesignTokens.accent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: DesignTokens.spacing12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Earn Screen Time',
                        style: TextStyle(
                          color: DesignTokens.textPrimary,
                          fontSize: DesignTokens.fontSizeBodySmall,
                          fontWeight: DesignTokens.fontWeightSemiBold,
                          fontFamily: DesignTokens.fontFamilyPrimary,
                        ),
                      ),
                      Text(
                        todayEarned > 0
                            ? '+${todayEarned}m earned • $completedCount/$totalCount habits'
                            : 'Complete habits to earn bonus minutes',
                        style: TextStyle(
                          color: DesignTokens.textMuted,
                          fontSize: DesignTokens.fontSizeCaption,
                          fontFamily: DesignTokens.fontFamilyPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: DesignTokens.textMuted, size: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCalendarTile(BuildContext context, PersonaTheme persona) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const CalendarScreen(),
          ),
        );
      },
      child: NoraCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: DesignTokens.accent.withValues(alpha: 0.15),
                borderRadius:
                    BorderRadius.circular(DesignTokens.radius10),
              ),
              child: Icon(
                Icons.calendar_month_rounded,
                color: DesignTokens.accent,
                size: 20,
              ),
            ),
            const SizedBox(width: DesignTokens.spacing12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Calendar',
                    style: TextStyle(
                      color: DesignTokens.textPrimary,
                      fontSize: DesignTokens.fontSizeBodySmall,
                      fontWeight: DesignTokens.fontWeightSemiBold,
                      fontFamily: DesignTokens.fontFamilyPrimary,
                    ),
                  ),
                  Text(
                    'View your task history and progress',
                    style: TextStyle(
                      color: DesignTokens.textMuted,
                      fontSize: DesignTokens.fontSizeCaption,
                      fontFamily: DesignTokens.fontFamilyPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: DesignTokens.textMuted, size: 20),
          ],
        ),
      ),
    );
  }

  void _showUnlinkDialog(
      BuildContext context, AccountabilityProvider accountability) {
    final pinController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DesignTokens.darkBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Remove Accountability Lock',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enter the guardian PIN to remove this lock.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: DesignTokens.fontSizeBodySmall,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              style: const TextStyle(
                fontSize: DesignTokens.fontSizeSubhead,
                letterSpacing: 6,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: '• • • •',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                  letterSpacing: 6,
                ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.06),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
            ),
          ),
          TextButton(
            onPressed: () async {
              final success =
                  await accountability.unlinkLock(pinController.text);
              if (success && ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Accountability lock removed'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: NoraCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: DesignTokens.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(DesignTokens.radius10),
              ),
              child: Icon(icon, color: DesignTokens.accent, size: 20),
            ),
            const SizedBox(width: DesignTokens.spacing12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: DesignTokens.textPrimary,
                      fontSize: DesignTokens.fontSizeBodySmall,
                      fontWeight: DesignTokens.fontWeightSemiBold,
                      fontFamily: DesignTokens.fontFamilyPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: DesignTokens.textMuted,
                      fontSize: DesignTokens.fontSizeCaption,
                      fontFamily: DesignTokens.fontFamilyPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: DesignTokens.textMuted, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountSection(
      BuildContext context, AuthProvider authProvider, PersonaTheme persona) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: persona.ageGroup.accountTitle,
          icon: Icons.account_circle_rounded,
          iconColor: DesignTokens.textMuted,
        ),
        const SizedBox(height: DesignTokens.spacing12),
        _buildSettingsTile(
          icon: Icons.info_rounded,
          title: 'About Nora',
          subtitle: 'Version 1.0.0',
          onTap: () {},
        ),
        _buildSettingsTile(
          icon: Icons.help_rounded,
          title: persona.ageGroup.helpTitle,
          subtitle: persona.ageGroup.helpSubtitle,
          onTap: () {},
        ),
        const SizedBox(height: DesignTokens.spacing16),
        SizedBox(
          width: double.infinity,
          child: NoraButton(
            label: persona.ageGroup.logoutLabel,
            icon: Icons.logout_rounded,
            outlined: true,
            onPressed: () => showLogoutConfirmation(context, authProvider),
          ),
        ),
      ],
    );
  }
}
