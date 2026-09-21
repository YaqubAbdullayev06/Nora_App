/// Predictive App Blocking Screen — AI-powered proactive procrastination prevention.
///
/// Shows predictions for when user might procrastinate and suggests
/// proactive blocks before distraction happens.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/design_tokens.dart';
import '../../../core/theme/persona_theme.dart';
import '../../../providers/persona_provider.dart';
import '../../../services/api_service.dart';
import '../../../services/ai_features_service.dart';

class PredictiveBlockingScreen extends StatefulWidget {
  const PredictiveBlockingScreen({super.key});

  @override
  State<PredictiveBlockingScreen> createState() =>
      _PredictiveBlockingScreenState();
}

class _PredictiveBlockingScreenState extends State<PredictiveBlockingScreen> {
  late AIFeaturesService _aiService;
  PredictiveResult? _result;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _aiService = AIFeaturesService(ApiService());
    _loadPredictions();
  }

  Future<void> _loadPredictions() async {
    setState(() => _isLoading = true);

    final personaProvider = context.read<PersonaProvider>();
    final ageGroup = personaProvider.persona.ageGroup.name;

    final now = DateTime.now();
    final dayOfWeek = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ][now.weekday - 1];

    final result = await _aiService.getPredictions(
      ageGroup: ageGroup,
      currentTime: '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
      dayOfWeek: dayOfWeek,
    );

    setState(() {
      _result = result;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final persona = Theme.of(context).extension<PersonaTheme>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Predictive Blocking'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPredictions,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _result == null
              ? const Center(child: Text('Failed to load predictions'))
              : RefreshIndicator(
                  onRefresh: _loadPredictions,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(DesignTokens.spacing16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSummaryCard(persona),
                        const SizedBox(height: DesignTokens.spacing16),
                        _buildRiskOverview(persona),
                        const SizedBox(height: DesignTokens.spacing16),
                        if (_result!.predictions.isNotEmpty)
                          _buildPredictionsSection(persona),
                        if (_result!.proactiveNudges.isNotEmpty) ...[
                          const SizedBox(height: DesignTokens.spacing16),
                          _buildNudgesSection(persona),
                        ],
                        if (_result!.suggestedBlock.isNotEmpty) ...[
                          const SizedBox(height: DesignTokens.spacing16),
                          _buildSuggestedBlocksSection(persona),
                        ],
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildSummaryCard(PersonaTheme? persona) {
    return Card(
      color: persona?.primary?.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.psychology, color: persona?.primary),
                const SizedBox(width: DesignTokens.spacing8),
                Text(
                  'AI Analysis',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.spacing8),
            Text(
              _result!.summary,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskOverview(PersonaTheme? persona) {
    final highRisk = _result!.highRiskCount;
    final mediumRisk =
        _result!.predictions.where((p) => p.riskLevel == 'medium').length;
    final lowRisk =
        _result!.predictions.where((p) => p.riskLevel == 'low').length;

    return Row(
      children: [
        _buildRiskChip('High Risk', highRisk, Colors.red, persona),
        const SizedBox(width: DesignTokens.spacing8),
        _buildRiskChip('Medium Risk', mediumRisk, Colors.orange, persona),
        const SizedBox(width: DesignTokens.spacing8),
        _buildRiskChip('Low Risk', lowRisk, Colors.green, persona),
      ],
    );
  }

  Widget _buildRiskChip(
      String label, int count, Color color, PersonaTheme? persona) {
    return Expanded(
      child: Card(
        color: count > 0 ? color.withOpacity(0.1) : null,
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.spacing12),
          child: Column(
            children: [
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPredictionsSection(PersonaTheme? persona) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Predictions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: DesignTokens.spacing12),
            ..._result!.predictions.map((p) => _buildPredictionCard(p, persona)),
          ],
        ),
      ),
    );
  }

  Widget _buildPredictionCard(Prediction prediction, PersonaTheme? persona) {
    final color = _getRiskColor(prediction.riskLevel);

    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.spacing12),
      padding: const EdgeInsets.all(DesignTokens.spacing12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  prediction.riskLevel.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: DesignTokens.spacing8),
              Text(
                prediction.time,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spacing8),
          Text(
            prediction.reason,
            style: const TextStyle(fontSize: 13),
          ),
          if (prediction.appsAtRisk.isNotEmpty) ...[
            const SizedBox(height: DesignTokens.spacing8),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: prediction.appsAtRisk
                  .map((app) => Chip(
                        label: Text(app, style: const TextStyle(fontSize: 10)),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ))
                  .toList(),
            ),
          ],
          const SizedBox(height: DesignTokens.spacing8),
          Row(
            children: [
              const Icon(Icons.lightbulb_outline, size: 14),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  prediction.suggestion,
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNudgesSection(PersonaTheme? persona) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Proactive Nudges',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: DesignTokens.spacing12),
            ..._result!.proactiveNudges.map((nudge) => ListTile(
                  leading: const Icon(Icons.notifications_active),
                  title: Text(nudge.message),
                  subtitle: Text('Trigger: ${nudge.triggerTime}'),
                  trailing: ActionChip(
                    label: const Text('Act Now'),
                    onPressed: () => _handleNudgeAction(nudge.action),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestedBlocksSection(PersonaTheme? persona) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Suggested Blocks',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: DesignTokens.spacing12),
            ..._result!.suggestedBlock.map((block) => ListTile(
                  leading: const Icon(Icons.block),
                  title: Text(block.packageName.split('.').last),
                  subtitle: Text(block.reason),
                  trailing: Text('Until ${block.blockUntil}'),
                )),
          ],
        ),
      ),
    );
  }

  Color _getRiskColor(String riskLevel) {
    switch (riskLevel) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  void _handleNudgeAction(String action) {
    // Navigate to appropriate screen based on action
    switch (action) {
      case 'start_focus':
        Navigator.pushNamed(context, '/focus');
        break;
      case 'block_apps':
        Navigator.pushNamed(context, '/app-scan');
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Action: $action')),
        );
    }
  }
}
