import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/design_tokens.dart';
import '../../../core/enums/age_group.dart';
import '../../../core/theme/persona_theme.dart';
import '../../../providers/persona_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/focus_protection_provider.dart';
import '../../../providers/agent_provider.dart';
import '../../../widgets/nora_components.dart';
import '../utils/age_group_helpers.dart';

Future<void> showFocusProtectionDialog(
    BuildContext context, PersonaProvider personaProvider) async {
  final focusProtection = context.read<FocusProtectionProvider>();
  final status = await focusProtection.requestAuthorization();
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
              focusProtection.selectApps();
            },
            child: Text('Choose apps',
                style: TextStyle(color: DesignTokens.accent)),
          ),
        if (status.supported && !status.blockingEnabled)
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              focusProtection.enableBlocking();
            },
            child: Text('Enable blocking',
                style: TextStyle(color: DesignTokens.accent)),
          ),
        if (status.blockingEnabled)
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              focusProtection.disableBlocking();
            },
            child: Text('Disable blocking',
                style: TextStyle(color: DesignTokens.danger)),
          ),
      ],
    ),
  );
}

Future<void> showAgentCapabilitiesDialog(
    BuildContext context, PersonaProvider personaProvider) async {
  try {
    final agentProvider = context.read<AgentProvider>();
    final data = await agentProvider.getAgentCapabilities();
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

Future<void> showNotificationsDialog(
    BuildContext context, AuthProvider authProvider) async {
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => const NotificationsDialog(),
  );
}

Future<void> showEditProfileSheet(
    BuildContext context, AuthProvider authProvider) async {
  final nameController =
      TextEditingController(text: authProvider.currentUser?.name ?? '');

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
                fontSize: DesignTokens.fontSizeH3,
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
                authProvider.updateProfile(name: nameController.text);
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

void showPersonaSwitcher(
    BuildContext context, PersonaProvider personaProvider) {
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
              final isSelected = personaProvider.ageGroup == group;
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
                  personaProvider.setAgeGroup(group);
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

void showLogoutConfirmation(
    BuildContext context, AuthProvider authProvider) {
  final persona = context.read<PersonaProvider>().persona;
  final ageGroup = persona.ageGroup;
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: DesignTokens.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radius20),
        side: BorderSide(color: DesignTokens.border, width: 1),
      ),
      title: Text(
        ageGroup.logoutTitle,
        style: TextStyle(
          color: DesignTokens.textPrimary,
          fontFamily: DesignTokens.fontFamilyDisplay,
        ),
      ),
      content: Text(
        ageGroup.logoutMessage,
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
            authProvider.logout();
            // Also clear AuthProvider (already handled above)
            try {
              context.read<AuthProvider>().logout();
            } catch (_) {}
            Navigator.pop(context);
            Navigator.pushReplacementNamed(context, '/login');
          },
          child: Text(
            ageGroup.logoutButtonLabel,
            style: TextStyle(color: DesignTokens.danger),
          ),
        ),
      ],
    ),
  );
}

class NotificationsDialog extends StatefulWidget {
  const NotificationsDialog({super.key});

  @override
  State<NotificationsDialog> createState() => _NotificationsDialogState();
}

class _NotificationsDialogState extends State<NotificationsDialog> {
  bool _focusReminders = true;
  bool _dailyDigest = false;
  bool _achievementAlerts = true;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
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
            value: _focusReminders,
            onChanged: (value) => setState(() => _focusReminders = value),
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
            value: _dailyDigest,
            onChanged: (value) => setState(() => _dailyDigest = value),
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
            value: _achievementAlerts,
            onChanged: (value) => setState(() => _achievementAlerts = value),
            activeThumbColor: DesignTokens.accent,
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child:
              Text('Cancel', style: TextStyle(color: DesignTokens.textMuted)),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Notification preferences saved!')),
            );
          },
          child:
              Text('Save', style: TextStyle(color: DesignTokens.accent)),
        ),
      ],
    );
  }
}
