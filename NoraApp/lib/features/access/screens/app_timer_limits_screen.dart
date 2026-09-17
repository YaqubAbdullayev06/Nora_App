import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/design_tokens.dart';
import '../../../providers/app_provider.dart';
import '../../../providers/app_timer_provider.dart';
import '../../../widgets/nora_components.dart';

/// App Timer Limits Screen — Configure per-app daily time limits.
/// Users can set limits, view usage, and see which apps are over limit.
class AppTimerLimitsScreen extends StatefulWidget {
  const AppTimerLimitsScreen({super.key});

  @override
  State<AppTimerLimitsScreen> createState() => _AppTimerLimitsScreenState();
}

class _AppTimerLimitsScreenState extends State<AppTimerLimitsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppTimerProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.background,
      body: SafeArea(
        child: Consumer2<AppProvider, AppTimerProvider>(
          builder: (context, appProvider, timer, _) {
            final persona = appProvider.persona;

            return CustomScrollView(
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(DesignTokens.spacing20),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: DesignTokens.surface,
                              borderRadius: BorderRadius.circular(DesignTokens.radius12),
                              border: Border.all(color: DesignTokens.border),
                            ),
                            child: Icon(
                              Icons.arrow_back_ios_rounded,
                              color: DesignTokens.textPrimary,
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: DesignTokens.spacing12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'App Timer Limits',
                                style: TextStyle(
                                  color: DesignTokens.textPrimary,
                                  fontSize: DesignTokens.fontSizeH2,
                                  fontWeight: DesignTokens.fontWeightBold,
                                  fontFamily: DesignTokens.fontFamilyDisplay,
                                ),
                              ),
                              Text(
                                timer.getSummary(),
                                style: TextStyle(
                                  color: DesignTokens.textMuted,
                                  fontSize: DesignTokens.fontSizeBodySmall,
                                  fontFamily: DesignTokens.fontFamilyPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Summary cards
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spacing20),
                    child: _buildSummaryCards(timer),
                  ),
                ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: DesignTokens.spacing24),
                ),

                // Exceeded apps warning
                if (timer.exceeded.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spacing20),
                      child: _buildExceededWarning(timer),
                    ),
                  ),

                if (timer.exceeded.isNotEmpty)
                  const SliverToBoxAdapter(
                    child: SizedBox(height: DesignTokens.spacing24),
                  ),

                // Active limits
                if (timer.limits.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spacing20),
                      child: SectionHeader(
                        title: 'Active Limits',
                        icon: Icons.timer_rounded,
                        iconColor: DesignTokens.warning,
                      ),
                    ),
                  ),

                if (timer.limits.isNotEmpty)
                  const SliverToBoxAdapter(
                    child: SizedBox(height: DesignTokens.spacing12),
                  ),

                if (timer.limits.isNotEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spacing20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final entries = timer.getSortedLimits();
                          if (index >= entries.length) return null;
                          final entry = entries[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: DesignTokens.spacing8),
                            child: _buildLimitCard(
                              entry.key,
                              timer.getAppName(entry.key),
                              entry.value,
                              timer.usage[entry.key] ?? 0,
                              timer.getProgress(entry.key),
                              timer.hasExceeded(entry.key),
                            ),
                          );
                        },
                        childCount: timer.limits.length,
                      ),
                    ),
                  ),

                // Add new limit button
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(DesignTokens.spacing20),
                    child: _buildAddLimitButton(context),
                  ),
                ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: DesignTokens.spacing40),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummaryCards(AppTimerProvider timer) {
    final totalLimited = timer.totalLimitedMinutes;
    final exceededCount = timer.exceeded.length;

    return Row(
      children: [
        Expanded(
          child: _buildMiniStat(
            '${timer.limits.length}',
            'Apps Limited',
            Icons.timer_rounded,
            DesignTokens.accent,
          ),
        ),
        const SizedBox(width: DesignTokens.spacing12),
        Expanded(
          child: _buildMiniStat(
            '${totalLimited}m',
            'Total Used',
            Icons.access_time_rounded,
            DesignTokens.success,
          ),
        ),
        const SizedBox(width: DesignTokens.spacing12),
        Expanded(
          child: _buildMiniStat(
            '$exceededCount',
            'Goals Met',
            Icons.check_circle_outline_rounded,
            exceededCount > 0 ? DesignTokens.accent : DesignTokens.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniStat(String value, String label, IconData icon, Color color) {
    return NoraCard(
      backgroundColor: color.withValues(alpha: 0.06),
      border: Border.all(color: color.withValues(alpha: 0.15)),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: DesignTokens.spacing8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: DesignTokens.fontSizeTitleMedium,
              fontWeight: DesignTokens.fontWeightBold,
              fontFamily: DesignTokens.fontFamilyDisplay,
            ),
          ),
          const SizedBox(height: DesignTokens.spacing2),
          Text(
            label,
            style: TextStyle(
              color: DesignTokens.textMuted,
              fontSize: DesignTokens.fontSizeTiny,
              fontFamily: DesignTokens.fontFamilyPrimary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildExceededWarning(AppTimerProvider timer) {
    return NoraCard(
      backgroundColor: DesignTokens.accent.withValues(alpha: 0.08),
      border: Border.all(color: DesignTokens.accent.withValues(alpha: 0.3)),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: DesignTokens.accent, size: 24),
          const SizedBox(width: DesignTokens.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${timer.exceeded.length} app(s) reached your goal',
                  style: TextStyle(
                    color: DesignTokens.accent,
                    fontSize: DesignTokens.fontSizeBody,
                    fontWeight: DesignTokens.fontWeightSemiBold,
                    fontFamily: DesignTokens.fontFamilyPrimary,
                  ),
                ),
                Text(
                  'These apps have reached their daily time goals',
                  style: TextStyle(
                    color: DesignTokens.accent.withValues(alpha: 0.8),
                    fontSize: DesignTokens.fontSizeCaption,
                    fontFamily: DesignTokens.fontFamilyPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLimitCard(
    String packageName,
    String appName,
    int limitMinutes,
    int usedMinutes,
    double progress,
    bool exceeded,
  ) {
    final remaining = (limitMinutes - usedMinutes).clamp(0, limitMinutes);
    final color = exceeded
        ? DesignTokens.accent
        : progress > 0.8
            ? DesignTokens.accentSecondary
            : DesignTokens.accent;

    return NoraCard(
      backgroundColor: exceeded
          ? DesignTokens.accent.withValues(alpha: 0.04)
          : DesignTokens.surface,
      border: Border.all(
        color: exceeded
            ? DesignTokens.accent.withValues(alpha: 0.3)
            : DesignTokens.border,
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // App icon placeholder
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(DesignTokens.radius8),
                ),
                child: Icon(
                  _getCategoryIcon(packageName),
                  color: color,
                  size: 18,
                ),
              ),
              const SizedBox(width: DesignTokens.spacing12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appName,
                      style: TextStyle(
                        color: DesignTokens.textPrimary,
                        fontSize: DesignTokens.fontSizeBody,
                        fontWeight: DesignTokens.fontWeightSemiBold,
                        fontFamily: DesignTokens.fontFamilyPrimary,
                      ),
                    ),
                    Text(
                      '$usedMinutes / $limitMinutes min today',
                      style: TextStyle(
                        color: DesignTokens.textMuted,
                        fontSize: DesignTokens.fontSizeCaption,
                        fontFamily: DesignTokens.fontFamilyPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              // Remaining time
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(DesignTokens.radius8),
                ),
                child: Text(
                  exceeded ? 'GOAL MET' : '${remaining}m left',
                  style: TextStyle(
                    color: color,
                    fontSize: DesignTokens.fontSizeExtraSmall,
                    fontWeight: DesignTokens.fontWeightBold,
                    fontFamily: DesignTokens.fontFamilyPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spacing8),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: DesignTokens.border.withValues(alpha: 0.3),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: DesignTokens.spacing8),
          // Action row
          Row(
            children: [
              // Edit button
              GestureDetector(
                onTap: () => _showEditDialog(packageName, appName, limitMinutes),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: DesignTokens.surface,
                    borderRadius: BorderRadius.circular(DesignTokens.radius4),
                    border: Border.all(color: DesignTokens.border),
                  ),
                  child: Text(
                    'Edit',
                    style: TextStyle(
                      color: DesignTokens.textMuted,
                      fontSize: DesignTokens.fontSizeExtraSmall,
                      fontFamily: DesignTokens.fontFamilyPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: DesignTokens.spacing8),
              // Remove button
              GestureDetector(
                onTap: () => _removeLimit(packageName, appName),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: DesignTokens.danger.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(DesignTokens.radius4),
                    border: Border.all(color: DesignTokens.danger.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    'Remove',
                    style: TextStyle(
                      color: DesignTokens.danger,
                      fontSize: DesignTokens.fontSizeExtraSmall,
                      fontFamily: DesignTokens.fontFamilyPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddLimitButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _showAddLimitDialog(context),
      child: NoraCard(
        backgroundColor: DesignTokens.accent.withValues(alpha: 0.08),
        border: Border.all(
          color: DesignTokens.accent.withValues(alpha: 0.3),
          width: 1,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [DesignTokens.accent, DesignTokens.accentSecondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
            ),
            const SizedBox(width: DesignTokens.spacing16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add App Limit',
                    style: TextStyle(
                      color: DesignTokens.textPrimary,
                      fontSize: DesignTokens.fontSizeBody,
                      fontWeight: DesignTokens.fontWeightSemiBold,
                      fontFamily: DesignTokens.fontFamilyPrimary,
                    ),
                  ),
                  Text(
                    'Set a daily time limit for an app',
                    style: TextStyle(
                      color: DesignTokens.textMuted,
                      fontSize: DesignTokens.fontSizeCaption,
                      fontFamily: DesignTokens.fontFamilyPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                color: DesignTokens.textMuted, size: 16),
          ],
        ),
      ),
    );
  }

  void _showAddLimitDialog(BuildContext context) {
    String selectedPackage = '';
    String selectedName = '';
    int selectedMinutes = 30;

    // Common apps to choose from
    final commonApps = [
      ('com.instagram.android', 'Instagram'),
      ('com.facebook.katana', 'Facebook'),
      ('com.twitter.android', 'Twitter/X'),
      ('com.zhiliaoapp.musically', 'TikTok'),
      ('com.google.android.youtube', 'YouTube'),
      ('com.spotify.music', 'Spotify'),
      ('com.whatsapp', 'WhatsApp'),
      ('com.discord', 'Discord'),
      ('com.reddit.frontpage', 'Reddit'),
      ('com.snapchat.android', 'Snapchat'),
      ('com.netflix.mediaclient', 'Netflix'),
      ('com.tiktok.ugc', 'TikTok'),
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: DesignTokens.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radius16),
          ),
          title: Text(
            'Add App Limit',
            style: TextStyle(
              color: DesignTokens.textPrimary,
              fontWeight: DesignTokens.fontWeightBold,
              fontFamily: DesignTokens.fontFamilyDisplay,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select an app to limit:',
                style: TextStyle(
                  color: DesignTokens.textMuted,
                  fontSize: DesignTokens.fontSizeCaption,
                  fontFamily: DesignTokens.fontFamilyPrimary,
                ),
              ),
              const SizedBox(height: DesignTokens.spacing12),
              // App selection
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: DesignTokens.background,
                  borderRadius: BorderRadius.circular(DesignTokens.radius8),
                  border: Border.all(color: DesignTokens.border),
                ),
                child: ListView.builder(
                  itemCount: commonApps.length,
                  itemBuilder: (context, index) {
                    final app = commonApps[index];
                    final isSelected = selectedPackage == app.$1;
                    return ListTile(
                      dense: true,
                      selected: isSelected,
                      selectedTileColor: DesignTokens.accent.withValues(alpha: 0.1),
                      title: Text(
                        app.$2,
                        style: TextStyle(
                          color: isSelected ? DesignTokens.accent : DesignTokens.textPrimary,
                          fontSize: DesignTokens.fontSizeBodySmall,
                          fontWeight: isSelected ? DesignTokens.fontWeightSemiBold : DesignTokens.fontWeightRegular,
                          fontFamily: DesignTokens.fontFamilyPrimary,
                        ),
                      ),
                      subtitle: Text(
                        app.$1,
                        style: TextStyle(
                          color: DesignTokens.textMuted,
                          fontSize: DesignTokens.fontSizeTiny,
                          fontFamily: DesignTokens.fontFamilyPrimary,
                        ),
                      ),
                      onTap: () {
                        setDialogState(() {
                          selectedPackage = app.$1;
                          selectedName = app.$2;
                        });
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: DesignTokens.spacing16),
              // Minutes slider
              Text(
                'Daily limit: ${selectedMinutes} minutes',
                style: TextStyle(
                  color: DesignTokens.textPrimary,
                  fontSize: DesignTokens.fontSizeBody,
                  fontWeight: DesignTokens.fontWeightSemiBold,
                  fontFamily: DesignTokens.fontFamilyPrimary,
                ),
              ),
              const SizedBox(height: DesignTokens.spacing8),
              Slider(
                value: selectedMinutes.toDouble(),
                min: 5,
                max: 240,
                divisions: 47,
                activeColor: DesignTokens.accent,
                inactiveColor: DesignTokens.border,
                onChanged: (value) {
                  setDialogState(() {
                    selectedMinutes = value.round();
                  });
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '5m',
                    style: TextStyle(
                      color: DesignTokens.textMuted,
                      fontSize: DesignTokens.fontSizeTiny,
                      fontFamily: DesignTokens.fontFamilyPrimary,
                    ),
                  ),
                  Text(
                    '4h',
                    style: TextStyle(
                      color: DesignTokens.textMuted,
                      fontSize: DesignTokens.fontSizeTiny,
                      fontFamily: DesignTokens.fontFamilyPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: DesignTokens.textMuted,
                  fontFamily: DesignTokens.fontFamilyPrimary,
                ),
              ),
            ),
            TextButton(
              onPressed: selectedPackage.isEmpty
                  ? null
                  : () {
                      context.read<AppTimerProvider>().setLimit(
                            selectedPackage,
                            selectedName,
                            selectedMinutes,
                          );
                      Navigator.pop(context);
                    },
              child: Text(
                'Add',
                style: TextStyle(
                  color: DesignTokens.accent,
                  fontWeight: DesignTokens.fontWeightBold,
                  fontFamily: DesignTokens.fontFamilyPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(String packageName, String appName, int currentMinutes) {
    int selectedMinutes = currentMinutes;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: DesignTokens.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radius16),
          ),
          title: Text(
            'Edit Limit',
            style: TextStyle(
              color: DesignTokens.textPrimary,
              fontWeight: DesignTokens.fontWeightBold,
              fontFamily: DesignTokens.fontFamilyDisplay,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                appName,
                style: TextStyle(
                  color: DesignTokens.accent,
                  fontSize: DesignTokens.fontSizeBody,
                  fontWeight: DesignTokens.fontWeightSemiBold,
                  fontFamily: DesignTokens.fontFamilyPrimary,
                ),
              ),
              const SizedBox(height: DesignTokens.spacing16),
              Text(
                'Daily limit: ${selectedMinutes} minutes',
                style: TextStyle(
                  color: DesignTokens.textPrimary,
                  fontSize: DesignTokens.fontSizeBody,
                  fontWeight: DesignTokens.fontWeightSemiBold,
                  fontFamily: DesignTokens.fontFamilyPrimary,
                ),
              ),
              const SizedBox(height: DesignTokens.spacing8),
              Slider(
                value: selectedMinutes.toDouble(),
                min: 5,
                max: 240,
                divisions: 47,
                activeColor: DesignTokens.accent,
                inactiveColor: DesignTokens.border,
                onChanged: (value) {
                  setDialogState(() {
                    selectedMinutes = value.round();
                  });
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '5m',
                    style: TextStyle(
                      color: DesignTokens.textMuted,
                      fontSize: DesignTokens.fontSizeTiny,
                      fontFamily: DesignTokens.fontFamilyPrimary,
                    ),
                  ),
                  Text(
                    '4h',
                    style: TextStyle(
                      color: DesignTokens.textMuted,
                      fontSize: DesignTokens.fontSizeTiny,
                      fontFamily: DesignTokens.fontFamilyPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: DesignTokens.textMuted,
                  fontFamily: DesignTokens.fontFamilyPrimary,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                context.read<AppTimerProvider>().setLimit(
                      packageName,
                      appName,
                      selectedMinutes,
                    );
                Navigator.pop(context);
              },
              child: Text(
                'Save',
                style: TextStyle(
                  color: DesignTokens.accent,
                  fontWeight: DesignTokens.fontWeightBold,
                  fontFamily: DesignTokens.fontFamilyPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _removeLimit(String packageName, String appName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: DesignTokens.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radius16),
        ),
        title: Text(
          'Remove Limit?',
          style: TextStyle(
            color: DesignTokens.textPrimary,
            fontWeight: DesignTokens.fontWeightBold,
            fontFamily: DesignTokens.fontFamilyDisplay,
          ),
        ),
        content: Text(
          'Remove the daily time limit for $appName?',
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
              style: TextStyle(
                color: DesignTokens.textMuted,
                fontFamily: DesignTokens.fontFamilyPrimary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              context.read<AppTimerProvider>().removeLimit(packageName);
              Navigator.pop(context);
            },
            child: Text(
              'Remove',
              style: TextStyle(
                color: DesignTokens.danger,
                fontWeight: DesignTokens.fontWeightBold,
                fontFamily: DesignTokens.fontFamilyPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String packageName) {
    if (packageName.contains('instagram')) return Icons.camera_alt_rounded;
    if (packageName.contains('facebook')) return Icons.facebook_rounded;
    if (packageName.contains('twitter')) return Icons.alternate_email_rounded;
    if (packageName.contains('tiktok')) return Icons.music_video_rounded;
    if (packageName.contains('youtube')) return Icons.play_circle_rounded;
    if (packageName.contains('spotify')) return Icons.music_note_rounded;
    if (packageName.contains('whatsapp')) return Icons.chat_rounded;
    if (packageName.contains('discord')) return Icons.forum_rounded;
    if (packageName.contains('reddit')) return Icons.forum_rounded;
    if (packageName.contains('snapchat')) return Icons.camera_alt_rounded;
    if (packageName.contains('netflix')) return Icons.movie_rounded;
    return Icons.apps_rounded;
  }
}
