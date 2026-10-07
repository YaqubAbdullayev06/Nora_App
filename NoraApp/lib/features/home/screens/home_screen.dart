import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/design_tokens.dart';
import '../../../providers/persona_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/focus_provider.dart';
import '../../../services/proactive_assist_service.dart';
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
    return Scaffold(
      backgroundColor: DesignTokens.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(DesignTokens.spacing20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              HomeHeader(personaProvider: context.read<PersonaProvider>(), authProvider: context.read<AuthProvider>()),
              const SizedBox(height: DesignTokens.spacing24),

              // Smart Insight (if available)
              _buildSmartInsight(context),
              const SizedBox(height: DesignTokens.spacing24),

              // Stats - Wrapped in Selector to prevent entire screen rebuilds on FocusProvider updates
              Selector<FocusProvider, FocusProvider>(
                selector: (_, provider) => provider,
                builder: (context, focusProvider, _) {
                  return HomeStats(personaProvider: context.read<PersonaProvider>(), focusProvider: focusProvider);
                },
              ),
              const SizedBox(height: DesignTokens.spacing24),

              // Quick Actions
              HomeActions(personaProvider: context.read<PersonaProvider>(), onPlanTap: widget.onPlanTap),
              const SizedBox(height: DesignTokens.spacing24),

              // Motivation
              HomeMotivation(personaProvider: context.read<PersonaProvider>()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSmartInsight(BuildContext context) {
    return Selector<FocusProvider, SmartSummary?>(
      selector: (_, provider) => provider.todaySummary,
      builder: (context, summary, _) {
        if (summary == null) return const SizedBox.shrink();
        return Column(
          children: [
            HomeInsight(summary: summary),
            const SizedBox(height: DesignTokens.spacing24),
          ],
        );
      },
    );
  }
}
