import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/design_tokens.dart';
import '../../../providers/app_provider.dart';
import '../../../services/proactive_assist_service.dart';
import '../../../models/app_info.dart';
import '../widgets/home_header.dart';
import '../widgets/home_insight.dart';
import '../widgets/home_stats.dart';
import '../widgets/home_actions.dart';
import '../widgets/home_motivation.dart';

/// Home Screen — age-adaptive dashboard.
/// Compact layout: header, insight card, stats, quick actions, motivation.
class HomeScreen extends StatefulWidget {
  final VoidCallback? onPlanTap;

  const HomeScreen({super.key, this.onPlanTap});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ProactiveAssistService _assistService = ProactiveAssistService();
  SmartSummary? _smartSummary;

  @override
  void initState() {
    super.initState();
    _loadSmartData();
  }

  Future<void> _loadSmartData() async {
    final summary = await _assistService.getTodaySummary();
    if (mounted) {
      setState(() => _smartSummary = summary);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: DesignTokens.background,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(DesignTokens.spacing20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  HomeHeader(provider: provider),
                  const SizedBox(height: DesignTokens.spacing24),

                  // Smart Insight (if available)
                  if (_smartSummary != null) ...[
                    HomeInsight(summary: _smartSummary!),
                    const SizedBox(height: DesignTokens.spacing24),
                  ],

                  // Stats
                  HomeStats(provider: provider),
                  const SizedBox(height: DesignTokens.spacing24),

                  // Quick Actions
                  HomeActions(provider: provider, onPlanTap: widget.onPlanTap),
                  const SizedBox(height: DesignTokens.spacing24),

                  // Motivation
                  HomeMotivation(provider: provider),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
