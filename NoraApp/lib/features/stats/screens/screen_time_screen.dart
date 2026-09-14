import 'package:flutter/material.dart';
import '../../../core/constants/design_tokens.dart';
import '../../../models/app_info.dart';
import '../../../services/screentime_service.dart';
import '../../../widgets/nora_components.dart';

/// Screen Time — detailed usage insights page.
class ScreenTimeScreen extends StatefulWidget {
  const ScreenTimeScreen({super.key});

  @override
  State<ScreenTimeScreen> createState() => _ScreenTimeScreenState();
}

class _ScreenTimeScreenState extends State<ScreenTimeScreen> {
  final ScreenTimeService _screenTimeService = ScreenTimeService();
  UsageStatsSummary? _todayUsage;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUsage();
  }

  Future<void> _loadUsage() async {
    try {
      await _screenTimeService.initialize();
      if (!_screenTimeService.isAvailable) {
        setState(() {
          _error = 'Screen time tracking is not available on this platform.';
          _isLoading = false;
        });
        return;
      }

      final usage = await _screenTimeService.getTodayUsage();
      if (mounted) {
        setState(() {
          _todayUsage = usage;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load screen time data: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded,
              color: DesignTokens.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Screen Time',
          style: TextStyle(
            color: DesignTokens.textPrimary,
            fontSize: DesignTokens.fontSizeH2,
            fontWeight: DesignTokens.fontWeightBold,
            fontFamily: DesignTokens.fontFamilyDisplay,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _buildContent(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spacing24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.screen_lock_portrait_rounded,
                size: 64, color: DesignTokens.textMuted),
            const SizedBox(height: DesignTokens.spacing16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: DesignTokens.textMuted,
                fontSize: DesignTokens.fontSizeBody,
                fontFamily: DesignTokens.fontFamilyPrimary,
              ),
            ),
            const SizedBox(height: DesignTokens.spacing24),
            ElevatedButton(
              onPressed: _loadUsage,
              style: ElevatedButton.styleFrom(
                backgroundColor: DesignTokens.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radius12),
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final usage = _todayUsage;
    final totalMinutes = usage?.totalScreenTimeMinutes ?? 0;
    final socialMinutes = usage?.socialMediaMinutes ?? 0;
    final productMinutes = usage?.productivityMinutes ?? 0;
    final entertainMinutes = usage?.entertainmentMinutes ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(DesignTokens.spacing20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Total screen time card
          NoraCard(
            backgroundColor: DesignTokens.primary.withValues(alpha: 0.1),
            border: Border.all(
                color: DesignTokens.primary.withValues(alpha: 0.3), width: 1),
            child: Column(
              children: [
                Text(
                  '$totalMinutes',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: DesignTokens.fontWeightBold,
                    fontFamily: DesignTokens.fontFamilyDisplay,
                    color: DesignTokens.primary,
                  ),
                ),
                Text(
                  'minutes today',
                  style: TextStyle(
                    color: DesignTokens.textMuted,
                    fontSize: DesignTokens.fontSizeBody,
                    fontFamily: DesignTokens.fontFamilyPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: DesignTokens.spacing24),

          // Category breakdown
          Text(
            'Usage Breakdown',
            style: TextStyle(
              color: DesignTokens.textPrimary,
              fontSize: DesignTokens.fontSizeH3,
              fontWeight: DesignTokens.fontWeightSemiBold,
              fontFamily: DesignTokens.fontFamilyDisplay,
            ),
          ),
          const SizedBox(height: DesignTokens.spacing12),
          _buildCategoryBar('Social Media', socialMinutes, totalMinutes,
              DesignTokens.danger),
          _buildCategoryBar('Productivity', productMinutes, totalMinutes,
              DesignTokens.success),
          _buildCategoryBar('Entertainment', entertainMinutes, totalMinutes,
              DesignTokens.accentSecondary),

          const SizedBox(height: DesignTokens.spacing24),

          // Top apps
          if (usage != null && usage.topApps.isNotEmpty) ...[
            Text(
              'Top Apps',
              style: TextStyle(
                color: DesignTokens.textPrimary,
                fontSize: DesignTokens.fontSizeH3,
                fontWeight: DesignTokens.fontWeightSemiBold,
                fontFamily: DesignTokens.fontFamilyDisplay,
              ),
            ),
            const SizedBox(height: DesignTokens.spacing12),
            ...usage.topApps.map((app) => _buildAppRow(
                  app.appName,
                  app.totalTimeMinutes,
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryBar(
      String label, int minutes, int total, Color color) {
    final fraction = total > 0 ? minutes / total : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.spacing12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: TextStyle(
                    color: DesignTokens.textPrimary,
                    fontSize: DesignTokens.fontSizeBodySmall,
                    fontFamily: DesignTokens.fontFamilyPrimary,
                  )),
              Text('${minutes}m',
                  style: TextStyle(
                    color: DesignTokens.textMuted,
                    fontSize: DesignTokens.fontSizeCaption,
                    fontFamily: DesignTokens.fontFamilyPrimary,
                  )),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(DesignTokens.radius8),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 8,
              backgroundColor: color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppRow(String name, int minutes) {
    return NoraCard(
      padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.spacing16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                color: DesignTokens.textPrimary,
                fontSize: DesignTokens.fontSizeBody,
                fontFamily: DesignTokens.fontFamilyPrimary,
              ),
            ),
          ),
          Text(
            '${minutes}m',
            style: TextStyle(
              color: DesignTokens.textMuted,
              fontSize: DesignTokens.fontSizeBodySmall,
              fontFamily: DesignTokens.fontFamilyPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
