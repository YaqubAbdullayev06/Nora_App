import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/design_tokens.dart';
import '../../../core/enums/age_group.dart';
import '../../../core/theme/persona_theme.dart';
import '../../../providers/app_provider.dart';
import '../../../widgets/nora_components.dart';

/// Profile Screen — age-adaptive settings and user info.
/// Baby: Parent controls, simple UI
/// Kid: Achievement display, parental settings
/// Teen: Social features, preferences
/// Adult: Full settings, export data, account management
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final persona = provider.persona;

        return Scaffold(
          backgroundColor: DesignTokens.background,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(DesignTokens.spacing20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, provider, persona),
                  const SizedBox(height: DesignTokens.spacing24),
                  _buildPersonaCard(persona),
                  const SizedBox(height: DesignTokens.spacing24),
                  _buildQuickStats(provider, persona),
                  const SizedBox(height: DesignTokens.spacing24),
                  _buildSettingsSection(context, provider, persona),
                  const SizedBox(height: DesignTokens.spacing24),
                  _buildAccountSection(context, provider, persona),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(
      BuildContext context, AppProvider provider, PersonaTheme persona) {
    return Row(
      children: [
        NoraMascot(size: 80, showGlow: true),
        const SizedBox(width: DesignTokens.spacing16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                provider.currentUser?.name ?? 'Explorer',
                style: TextStyle(
                  color: DesignTokens.textPrimary,
                  fontSize: DesignTokens.fontSizeH2,
                  fontWeight: DesignTokens.fontWeightBold,
                  fontFamily: DesignTokens.fontFamilyDisplay,
                ),
              ),
              Text(
                provider.currentUser?.email ?? 'explorer@nora.app',
                style: TextStyle(
                  color: DesignTokens.textMuted,
                  fontSize: DesignTokens.fontSizeBodySmall,
                  fontFamily: DesignTokens.fontFamilyPrimary,
                ),
              ),
              const SizedBox(height: DesignTokens.spacing4),
              AgeGroupBadge(),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => _showEditProfile(context, provider),
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
    final features = _getFeaturesForAgeGroup(persona.ageGroup);
    return Wrap(
      spacing: DesignTokens.spacing8,
      runSpacing: DesignTokens.spacing8,
      children: features.map((feature) {
        return NoraBadge(
          label: feature['label']!,
          icon: _getFeatureIcon(feature['icon']!),
          color: persona.primary,
        );
      }).toList(),
    );
  }

  Widget _buildQuickStats(AppProvider provider, PersonaTheme persona) {
    return Row(
      children: [
        Expanded(
          child: StatsCard(
            label: _getScoreLabel(persona.ageGroup),
            value: '${provider.focusScore}',
            icon: Icons.star_rounded,
            color: DesignTokens.accent,
          ),
        ),
        const SizedBox(width: DesignTokens.spacing12),
        Expanded(
          child: StatsCard(
            label: _getStreakLabel(persona.ageGroup),
            value: '${provider.streakDays}',
            icon: Icons.local_fire_department_rounded,
            color: DesignTokens.warning,
          ),
        ),
        const SizedBox(width: DesignTokens.spacing12),
        Expanded(
          child: StatsCard(
            label: _getSessionsLabel(persona.ageGroup),
            value: '${provider.sessionsCompleted}',
            icon: Icons.check_circle_rounded,
            color: DesignTokens.success,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsSection(
      BuildContext context, AppProvider provider, PersonaTheme persona) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: _getSettingsTitle(persona.ageGroup),
          icon: Icons.settings_rounded,
          iconColor: DesignTokens.textMuted,
        ),
        const SizedBox(height: DesignTokens.spacing12),
        _buildSettingsTile(
          icon: Icons.person_rounded,
          title: 'Edit Profile',
          subtitle: _getEditProfileSubtitle(persona.ageGroup),
          onTap: () => _showEditProfile(context, provider),
        ),
        _buildSettingsTile(
          icon: Icons.notifications_rounded,
          title: 'Notifications',
          subtitle: _getNotificationSubtitle(persona.ageGroup),
          onTap: () => _showNotifications(context, provider),
        ),
        _buildSettingsTile(
          icon: Icons.shield_rounded,
          title: 'Focus protection',
          subtitle: 'Choose permissions to block distracting apps',
          onTap: () => _showFocusProtection(context, provider),
        ),
        _buildSettingsTile(
          icon: Icons.auto_awesome_rounded,
          title: 'Nora capabilities',
          subtitle: 'View the skills available to your AI assistant',
          onTap: () => _showAgentCapabilities(context, provider),
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
            onTap: () => _showPersonaSwitcher(context, provider),
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

  Future<void> _showFocusProtection(
      BuildContext context, AppProvider provider) async {
    final status = await provider.requestFocusProtectionAuthorization();
    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: DesignTokens.surface,
        title: Text(
          'Focus protection',
          style: TextStyle(
            color: DesignTokens.textPrimary,
            fontFamily: DesignTokens.fontFamilyDisplay,
          ),
        ),
        content: Text(
          status.message,
          style: TextStyle(
            color: DesignTokens.textMuted,
            fontFamily: DesignTokens.fontFamilyPrimary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child:
                Text('Close', style: TextStyle(color: DesignTokens.textMuted)),
          ),
          if (status.supported)
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                provider.selectFocusApps();
              },
              child: Text('Choose apps',
                  style: TextStyle(color: DesignTokens.accent)),
            ),
          if (status.supported && !status.blockingEnabled)
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                provider.enableFocusProtection();
              },
              child: Text('Enable blocking',
                  style: TextStyle(color: DesignTokens.accent)),
            ),
          if (status.blockingEnabled)
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                provider.disableFocusProtection();
              },
              child: Text('Disable blocking',
                  style: TextStyle(color: DesignTokens.danger)),
            ),
        ],
      ),
    );
  }

  Future<void> _showAgentCapabilities(
      BuildContext context, AppProvider provider) async {
    try {
      final data = await provider.getAgentCapabilities();
      if (!context.mounted) return;
      final capabilities = data['capabilities'] as Map<String, dynamic>? ?? {};
      final restricted = (data['restricted'] as List<dynamic>? ?? [])
          .map((item) => item.toString())
          .toList();

      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: DesignTokens.surface,
          title: Text(
            'Nora capabilities',
            style: TextStyle(
              color: DesignTokens.textPrimary,
              fontFamily: DesignTokens.fontFamilyDisplay,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ...capabilities.entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      '${entry.key}: ${(entry.value as List<dynamic>).join(', ')}',
                      style: TextStyle(
                        color: DesignTokens.textPrimary,
                        fontFamily: DesignTokens.fontFamilyPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Restricted for safety: ${restricted.join(', ')}',
                  style: TextStyle(
                    color: DesignTokens.textMuted,
                    fontSize: DesignTokens.fontSizeCaption,
                    fontFamily: DesignTokens.fontFamilyPrimary,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child:
                  Text('Close', style: TextStyle(color: DesignTokens.accent)),
            ),
          ],
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not load Nora capabilities: $error'),
          backgroundColor: DesignTokens.danger,
        ),
      );
    }
  }

  Future<void> _showNotifications(
      BuildContext context, AppProvider provider) async {
    bool focusReminders = true;
    bool dailyDigest = false;
    bool achievementAlerts = true;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: DesignTokens.surface,
          title: Text(
            'Notifications',
            style: TextStyle(
              color: DesignTokens.textPrimary,
              fontFamily: DesignTokens.fontFamilyDisplay,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: Text(
                  'Focus reminders',
                  style: TextStyle(
                    color: DesignTokens.textPrimary,
                    fontFamily: DesignTokens.fontFamilyPrimary,
                  ),
                ),
                subtitle: Text(
                  'Get reminded when it\'s time to focus',
                  style: TextStyle(
                    color: DesignTokens.textMuted,
                    fontSize: DesignTokens.fontSizeCaption,
                    fontFamily: DesignTokens.fontFamilyPrimary,
                  ),
                ),
                value: focusReminders,
                onChanged: (value) =>
                    setDialogState(() => focusReminders = value),
                activeThumbColor: DesignTokens.accent,
                contentPadding: EdgeInsets.zero,
              ),
              SwitchListTile(
                title: Text(
                  'Daily digest',
                  style: TextStyle(
                    color: DesignTokens.textPrimary,
                    fontFamily: DesignTokens.fontFamilyPrimary,
                  ),
                ),
                subtitle: Text(
                  'Summary of your daily progress',
                  style: TextStyle(
                    color: DesignTokens.textMuted,
                    fontSize: DesignTokens.fontSizeCaption,
                    fontFamily: DesignTokens.fontFamilyPrimary,
                  ),
                ),
                value: dailyDigest,
                onChanged: (value) =>
                    setDialogState(() => dailyDigest = value),
                activeThumbColor: DesignTokens.accent,
                contentPadding: EdgeInsets.zero,
              ),
              SwitchListTile(
                title: Text(
                  'Achievement alerts',
                  style: TextStyle(
                    color: DesignTokens.textPrimary,
                    fontFamily: DesignTokens.fontFamilyPrimary,
                  ),
                ),
                subtitle: Text(
                  'Celebrate when you unlock milestones',
                  style: TextStyle(
                    color: DesignTokens.textMuted,
                    fontSize: DesignTokens.fontSizeCaption,
                    fontFamily: DesignTokens.fontFamilyPrimary,
                  ),
                ),
                value: achievementAlerts,
                onChanged: (value) =>
                    setDialogState(() => achievementAlerts = value),
                activeThumbColor: DesignTokens.accent,
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child:
                  Text('Cancel', style: TextStyle(color: DesignTokens.textMuted)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Notification preferences saved!')),
                );
              },
              child:
                  Text('Save', style: TextStyle(color: DesignTokens.accent)),
            ),
          ],
        ),
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
      BuildContext context, AppProvider provider, PersonaTheme persona) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: _getAccountTitle(persona.ageGroup),
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
          title: _getHelpTitle(persona.ageGroup),
          subtitle: _getHelpSubtitle(persona.ageGroup),
          onTap: () {},
        ),
        const SizedBox(height: DesignTokens.spacing16),
        // Logout button
        SizedBox(
          width: double.infinity,
          child: NoraButton(
            label: _getLogoutLabel(persona.ageGroup),
            icon: Icons.logout_rounded,
            outlined: true,
            onPressed: () => _showLogoutConfirmation(context, provider),
          ),
        ),
      ],
    );
  }

  void _showEditProfile(BuildContext context, AppProvider provider) {
    final nameController =
        TextEditingController(text: provider.currentUser?.name ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: DesignTokens.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Edit Profile',
                style: TextStyle(
                  color: DesignTokens.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: DesignTokens.fontFamilyDisplay,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                style: TextStyle(color: DesignTokens.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Name',
                  labelStyle: TextStyle(color: DesignTokens.textMuted),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),
              NoraButton(
                label: 'Save Changes',
                expanded: true,
                onPressed: () {
                  provider.updateProfile(name: nameController.text);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Profile updated successfully!')),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _showPersonaSwitcher(BuildContext context, AppProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: DesignTokens.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: DesignTokens.spacing12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: DesignTokens.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: DesignTokens.spacing16),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.spacing20),
                child: Text(
                  'Switch Persona',
                  style: TextStyle(
                    color: DesignTokens.textPrimary,
                    fontSize: DesignTokens.fontSizeH3,
                    fontWeight: DesignTokens.fontWeightSemiBold,
                    fontFamily: DesignTokens.fontFamilyDisplay,
                  ),
                ),
              ),
              const SizedBox(height: DesignTokens.spacing16),
              ...AgeGroup.values.map((group) {
                final theme = PersonaTheme.forAgeGroup(group);
                final isSelected = provider.ageGroup == group;
                return ListTile(
                  leading: SvgPicture.asset(
                    theme.mascotAssetPath,
                    width: 24,
                    height: 24,
                  ),
                  title: Text(
                    '${group.displayName} (${theme.mascotName})',
                    style: TextStyle(
                      color:
                          isSelected ? theme.primary : DesignTokens.textPrimary,
                      fontWeight: isSelected
                          ? DesignTokens.fontWeightSemiBold
                          : DesignTokens.fontWeightRegular,
                      fontFamily: DesignTokens.fontFamilyPrimary,
                    ),
                  ),
                  subtitle: Text(
                    theme.tagline,
                    style: TextStyle(
                      color: DesignTokens.textMuted,
                      fontSize: DesignTokens.fontSizeCaption,
                      fontFamily: DesignTokens.fontFamilyPrimary,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(Icons.check_circle_rounded, color: theme.primary)
                      : null,
                  onTap: () {
                    provider.setAgeGroup(group);
                    Navigator.pop(context);
                  },
                );
              }),
              const SizedBox(height: DesignTokens.spacing16),
            ],
          ),
        );
      },
    );
  }

  void _showLogoutConfirmation(BuildContext context, AppProvider provider) {
    final persona = provider.persona;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: DesignTokens.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radius20),
          side: BorderSide(color: DesignTokens.border, width: 1),
        ),
        title: Text(
          _getLogoutTitle(persona.ageGroup),
          style: TextStyle(
            color: DesignTokens.textPrimary,
            fontFamily: DesignTokens.fontFamilyDisplay,
          ),
        ),
        content: Text(
          _getLogoutMessage(persona.ageGroup),
          style: TextStyle(
            color: DesignTokens.textMuted,
            fontFamily: DesignTokens.fontFamilyPrimary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: DesignTokens.textMuted),
            ),
          ),
          TextButton(
            onPressed: () {
              provider.logout();
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: Text(
              _getLogoutButtonLabel(persona.ageGroup),
              style: TextStyle(color: DesignTokens.danger),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Age-specific helpers ───

  String _getScoreLabel(AgeGroup group) {
    switch (group) {
      case AgeGroup.baby:
        return 'Stars';
      case AgeGroup.child:
        return 'Stars';
      case AgeGroup.kid:
        return 'Points';
      case AgeGroup.teen:
        return 'XP';
      case AgeGroup.adult:
        return 'Score';
    }
  }

  String _getStreakLabel(AgeGroup group) {
    switch (group) {
      case AgeGroup.baby:
        return 'Days';
      case AgeGroup.child:
        return 'Days';
      case AgeGroup.kid:
        return 'Streak';
      case AgeGroup.teen:
        return 'Streak';
      case AgeGroup.adult:
        return 'Streak';
    }
  }

  String _getSessionsLabel(AgeGroup group) {
    switch (group) {
      case AgeGroup.baby:
        return 'Plays';
      case AgeGroup.child:
        return 'Plays';
      case AgeGroup.kid:
        return 'Quests';
      case AgeGroup.teen:
        return 'Sessions';
      case AgeGroup.adult:
        return 'Sessions';
    }
  }

  String _getSettingsTitle(AgeGroup group) {
    switch (group) {
      case AgeGroup.baby:
        return 'Settings';
      case AgeGroup.child:
        return 'Settings';
      case AgeGroup.kid:
        return 'Options';
      case AgeGroup.teen:
        return 'Settings';
      case AgeGroup.adult:
        return 'Settings';
    }
  }

  String _getEditProfileSubtitle(AgeGroup group) {
    switch (group) {
      case AgeGroup.baby:
        return 'Ask a grown-up to help';
      case AgeGroup.child:
        return 'Ask a grown-up to help';
      case AgeGroup.kid:
        return 'Change your name or avatar';
      case AgeGroup.teen:
        return 'Update your info';
      case AgeGroup.adult:
        return 'Manage your account';
    }
  }

  String _getNotificationSubtitle(AgeGroup group) {
    switch (group) {
      case AgeGroup.baby:
        return 'Fun reminders';
      case AgeGroup.child:
        return 'Fun reminders';
      case AgeGroup.kid:
        return 'Alert me for quests';
      case AgeGroup.teen:
        return 'Customize alerts';
      case AgeGroup.adult:
        return 'Manage notifications';
    }
  }

  String _getAccountTitle(AgeGroup group) {
    switch (group) {
      case AgeGroup.baby:
        return 'More';
      case AgeGroup.child:
        return 'More';
      case AgeGroup.kid:
        return 'Account';
      case AgeGroup.teen:
        return 'Account';
      case AgeGroup.adult:
        return 'Account';
    }
  }

  String _getHelpTitle(AgeGroup group) {
    switch (group) {
      case AgeGroup.baby:
        return 'Help';
      case AgeGroup.child:
        return 'Help';
      case AgeGroup.kid:
        return 'Get Help';
      case AgeGroup.teen:
        return 'Support';
      case AgeGroup.adult:
        return 'Help & Support';
    }
  }

  String _getHelpSubtitle(AgeGroup group) {
    switch (group) {
      case AgeGroup.baby:
        return 'Ask a grown-up';
      case AgeGroup.child:
        return 'Ask a grown-up';
      case AgeGroup.kid:
        return 'Chat with Nora';
      case AgeGroup.teen:
        return 'FAQ and contact';
      case AgeGroup.adult:
        return 'FAQ, contact, docs';
    }
  }

  String _getLogoutLabel(AgeGroup group) {
    switch (group) {
      case AgeGroup.baby:
        return 'Bye-bye!';
      case AgeGroup.child:
        return 'Bye-bye!';
      case AgeGroup.kid:
        return 'Log Out';
      case AgeGroup.teen:
        return 'Sign Out';
      case AgeGroup.adult:
        return 'Sign Out';
    }
  }

  String _getLogoutTitle(AgeGroup group) {
    switch (group) {
      case AgeGroup.baby:
        return 'Say bye-bye?';
      case AgeGroup.child:
        return 'Say bye-bye?';
      case AgeGroup.kid:
        return 'Log out?';
      case AgeGroup.teen:
        return 'Sign out?';
      case AgeGroup.adult:
        return 'Sign out?';
    }
  }

  String _getLogoutMessage(AgeGroup group) {
    switch (group) {
      case AgeGroup.baby:
        return 'Nora will miss you! See you soon!';
      case AgeGroup.child:
        return 'Nora will miss you! See you soon!';
      case AgeGroup.kid:
        return 'Your progress will be saved. Come back soon!';
      case AgeGroup.teen:
        return 'Your data is safe. See you next time!';
      case AgeGroup.adult:
        return 'Your session will end. All data is saved.';
    }
  }

  String _getLogoutButtonLabel(AgeGroup group) {
    switch (group) {
      case AgeGroup.baby:
        return 'Bye!';
      case AgeGroup.child:
        return 'Bye!';
      case AgeGroup.kid:
        return 'Log Out';
      case AgeGroup.teen:
        return 'Sign Out';
      case AgeGroup.adult:
        return 'Sign Out';
    }
  }

  List<Map<String, String>> _getFeaturesForAgeGroup(AgeGroup group) {
    switch (group) {
      case AgeGroup.baby:
        return [
          {'label': 'Play', 'icon': 'sports_esports'},
          {'label': 'Colors', 'icon': 'palette'},
          {'label': 'Music', 'icon': 'music_note'},
        ];
      case AgeGroup.child:
        return [
          {'label': 'Play', 'icon': 'sports_esports'},
          {'label': 'Colors', 'icon': 'palette'},
          {'label': 'Music', 'icon': 'music_note'},
        ];
      case AgeGroup.kid:
        return [
          {'label': 'Adventures', 'icon': 'explore'},
          {'label': 'Games', 'icon': 'sports_esports'},
          {'label': 'Learning', 'icon': 'school'},
        ];
      case AgeGroup.teen:
        return [
          {'label': 'Focus', 'icon': 'center_focus_strong'},
          {'label': 'Social', 'icon': 'people'},
          {'label': 'Goals', 'icon': 'flag'},
        ];
      case AgeGroup.adult:
        return [
          {'label': 'Productivity', 'icon': 'trending_up'},
          {'label': 'Analytics', 'icon': 'analytics'},
          {'label': 'Wellness', 'icon': 'spa'},
        ];
    }
  }

  IconData _getFeatureIcon(String icon) {
    switch (icon) {
      case 'sports_esports':
        return Icons.sports_esports_rounded;
      case 'palette':
        return Icons.palette_rounded;
      case 'music_note':
        return Icons.music_note_rounded;
      case 'explore':
        return Icons.explore_rounded;
      case 'school':
        return Icons.school_rounded;
      case 'center_focus_strong':
        return Icons.center_focus_strong_rounded;
      case 'people':
        return Icons.people_rounded;
      case 'flag':
        return Icons.flag_rounded;
      case 'trending_up':
        return Icons.trending_up_rounded;
      case 'analytics':
        return Icons.analytics_rounded;
      case 'spa':
        return Icons.spa_rounded;
      default:
        return Icons.star_rounded;
    }
  }
}
