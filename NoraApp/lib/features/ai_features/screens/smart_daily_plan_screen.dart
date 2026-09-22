/// Smart Daily Plan Screen — AI-generated optimized daily schedule.
///
/// Shows a visual timeline of focus blocks, breaks, and transitions
/// based on the user's goals, energy patterns, and available time.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/design_tokens.dart';
import '../../../core/theme/persona_theme.dart';
import '../../../providers/persona_provider.dart';
import '../../../services/api_service.dart';
import '../../../services/ai_features_service.dart';

class SmartDailyPlanScreen extends StatefulWidget {
  const SmartDailyPlanScreen({super.key});

  @override
  State<SmartDailyPlanScreen> createState() => _SmartDailyPlanScreenState();
}

class _SmartDailyPlanScreenState extends State<SmartDailyPlanScreen> {
  late AIFeaturesService _aiService;
  DailyPlan? _plan;
  bool _isLoading = true;
  String _energyPattern = 'normal';
  double _availableHours = 8.0;
  final List<String> _selectedGoals = [];

  final List<String> _availableGoals = [
    'Deep work',
    'Creative tasks',
    'Email & admin',
    'Learning',
    'Exercise',
    'Reading',
    'Side project',
    'Meetings',
  ];

  @override
  void initState() {
    super.initState();
    _aiService = AIFeaturesService(ApiService());
    _generatePlan();
  }

  Future<void> _generatePlan() async {
    setState(() => _isLoading = true);

    final personaProvider = context.read<PersonaProvider>();
    final ageGroup = personaProvider.persona.ageGroup.name;

    final plan = await _aiService.generateDailyPlan(
      ageGroup: ageGroup,
      goals: _selectedGoals,
      availableHours: _availableHours,
      energyPattern: _energyPattern,
    );

    setState(() {
      _plan = plan;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final persona = Theme.of(context).extension<PersonaTheme>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Daily Plan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _generatePlan,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _plan == null
              ? const Center(child: Text('Failed to generate plan'))
              : RefreshIndicator(
                  onRefresh: _generatePlan,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(DesignTokens.spacing16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSettingsCard(persona),
                        const SizedBox(height: DesignTokens.spacing16),
                        _buildSummaryCard(persona),
                        const SizedBox(height: DesignTokens.spacing16),
                        _buildTimeline(persona),
                        const SizedBox(height: DesignTokens.spacing16),
                        if (_plan!.tip.isNotEmpty) _buildTipCard(persona),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildSettingsCard(PersonaTheme? persona) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Plan Settings',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: persona?.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: DesignTokens.spacing12),
            Row(
              children: [
                const Icon(Icons.access_time, size: 20),
                const SizedBox(width: DesignTokens.spacing8),
                Expanded(
                  child: Slider(
                    value: _availableHours,
                    min: 2,
                    max: 12,
                    divisions: 10,
                    label: '${_availableHours.toStringAsFixed(1)} hours',
                    onChanged: (value) {
                      setState(() => _availableHours = value);
                    },
                  ),
                ),
                Text('${_availableHours.toStringAsFixed(1)}h'),
              ],
            ),
            const SizedBox(height: DesignTokens.spacing8),
            Wrap(
              spacing: DesignTokens.spacing8,
              children: [
                _buildEnergyChip('morning_person', 'Morning Person', Icons.wb_sunny),
                _buildEnergyChip('normal', 'Normal', Icons.wb_cloudy),
                _buildEnergyChip('night_owl', 'Night Owl', Icons.nightlight_round),
              ],
            ),
            const SizedBox(height: DesignTokens.spacing12),
            Wrap(
              spacing: DesignTokens.spacing8,
              runSpacing: DesignTokens.spacing8,
              children: _availableGoals.map((goal) {
                final isSelected = _selectedGoals.contains(goal);
                return FilterChip(
                  label: Text(goal),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedGoals.add(goal);
                      } else {
                        _selectedGoals.remove(goal);
                      }
                    });
                  },
                  selectedColor: persona?.primary.withValues(alpha: 0.2),
                );
              }).toList(),
            ),
            const SizedBox(height: DesignTokens.spacing12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _generatePlan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: persona?.primary,
                ),
                child: const Text('Regenerate Plan'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnergyChip(String value, String label, IconData icon) {
    final isSelected = _energyPattern == value;
    return ChoiceChip(
      label: Text(label),
      avatar: Icon(icon, size: 18),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _energyPattern = value);
        }
      },
    );
  }

  Widget _buildSummaryCard(PersonaTheme? persona) {
    return Card(
      color: persona?.primary.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _plan!.summary,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(height: DesignTokens.spacing8),
            Row(
              children: [
                _buildStatChip(
                  Icons.timer,
                  '${_plan!.totalFocusMinutes}m focus',
                  persona?.primary,
                ),
                const SizedBox(width: DesignTokens.spacing8),
                _buildStatChip(
                  Icons.coffee,
                  '${_plan!.totalBreakMinutes}m breaks',
                  Colors.green,
                ),
                const SizedBox(width: DesignTokens.spacing8),
                _buildStatChip(
                  Icons.view_timeline,
                  '${_plan!.plan.length} blocks',
                  Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label, Color? color) {
    return Chip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(label, style: TextStyle(fontSize: 12)),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildTimeline(PersonaTheme? persona) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Schedule',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: DesignTokens.spacing12),
            ..._plan!.plan.map((block) => _buildTimelineBlock(block, persona)),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineBlock(PlanBlock block, PersonaTheme? persona) {
    final color = block.isFocus
        ? persona?.primary ?? Colors.blue
        : Colors.green;

    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.spacing8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              if (block != _plan!.plan.last)
                Container(
                  width: 2,
                  height: 40,
                  color: color.withOpacity(0.3),
                ),
            ],
          ),
          const SizedBox(width: DesignTokens.spacing12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(DesignTokens.spacing12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '${block.time} - ${block.endTime}',
                        style: TextStyle(
                          fontSize: 12,
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          block.isFocus ? 'FOCUS' : 'BREAK',
                          style: TextStyle(
                            fontSize: 10,
                            color: color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: DesignTokens.spacing4),
                  Text(
                    block.title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    block.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipCard(PersonaTheme? persona) {
    return Card(
      color: Colors.amber.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spacing16),
        child: Row(
          children: [
            Icon(Icons.lightbulb, color: Colors.amber[700]),
            const SizedBox(width: DesignTokens.spacing12),
            Expanded(
              child: Text(
                _plan!.tip,
                style: TextStyle(
                  color: Colors.amber[900],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
