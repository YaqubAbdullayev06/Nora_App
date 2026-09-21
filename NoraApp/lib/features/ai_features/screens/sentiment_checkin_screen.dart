/// Sentiment-Aware Check-in Screen — AI-powered mood detection and empathetic responses.
///
/// Analyzes user's messages for sentiment and provides age-appropriate
/// supportive responses with actionable suggestions.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/design_tokens.dart';
import '../../../core/theme/persona_theme.dart';
import '../../../providers/persona_provider.dart';
import '../../../services/api_service.dart';
import '../../../services/ai_features_service.dart';

class SentimentCheckinScreen extends StatefulWidget {
  const SentimentCheckinScreen({super.key});

  @override
  State<SentimentCheckinScreen> createState() => _SentimentCheckinScreenState();
}

class _SentimentCheckinScreenState extends State<SentimentCheckinScreen>
    with SingleTickerProviderStateMixin {
  late AIFeaturesService _aiService;
  final TextEditingController _messageController = TextEditingController();
  final List<_ChatMessage> _messages = [];
  bool _isAnalyzing = false;
  SentimentResult? _lastResult;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _aiService = AIFeaturesService(ApiService());
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );

    // Add welcome message
    _messages.add(_ChatMessage(
      text: "Hey! How are you feeling today? I'm here to listen.",
      isUser: false,
      sentiment: 'neutral',
    ));
  }

  @override
  void dispose() {
    _messageController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _messageController.clear();
      _isAnalyzing = true;
    });

    final personaProvider = context.read<PersonaProvider>();
    final ageGroup = personaProvider.persona.ageGroup.name;

    final result = await _aiService.checkSentiment(
      message: text,
      ageGroup: ageGroup,
    );

    setState(() {
      _lastResult = result;
      _messages.add(_ChatMessage(
        text: result.response,
        isUser: false,
        sentiment: result.sentiment,
        suggestion: result.suggestion,
        moodScore: result.moodScore,
      ));
      _isAnalyzing = false;
    });

    _animController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final persona = Theme.of(context).extension<PersonaTheme>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('How Are You Feeling?'),
        actions: [
          if (_lastResult != null)
            IconButton(
              icon: const Icon(Icons.mood),
              onPressed: _showMoodHistory,
            ),
        ],
      ),
      body: Column(
        children: [
          if (_lastResult != null) _buildMoodIndicator(persona),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(DesignTokens.spacing16),
              itemCount: _messages.length + (_isAnalyzing ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return _buildTypingIndicator(persona);
                }
                return _buildMessageBubble(_messages[index], persona);
              },
            ),
          ),
          _buildInputArea(persona),
        ],
      ),
    );
  }

  Widget _buildMoodIndicator(PersonaTheme? persona) {
    final result = _lastResult!;
    final moodColor = _getMoodColor(result.sentiment);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spacing16,
        vertical: DesignTokens.spacing12,
      ),
      color: moodColor.withOpacity(0.1),
      child: Row(
        children: [
          Icon(_getMoodIcon(result.sentiment), color: moodColor, size: 28),
          const SizedBox(width: DesignTokens.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mood: ${result.sentiment.toUpperCase()}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: moodColor,
                  ),
                ),
                Text(
                  'Score: ${result.moodScore}/10 • Confidence: ${(result.confidence * 100).toInt()}%',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          if (result.suggestion.isNotEmpty)
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: moodColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  result.suggestion,
                  style: TextStyle(
                    fontSize: 11,
                    color: moodColor,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(_ChatMessage msg, PersonaTheme? persona) {
    final isUser = msg.isUser;
    final bubbleColor = isUser
        ? (persona?.primary ?? Colors.blue)
        : _getMoodColor(msg.sentiment).withOpacity(0.15);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: DesignTokens.spacing12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(DesignTokens.spacing12),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.circular(16).copyWith(
                  bottomRight: isUser ? const Radius.circular(4) : null,
                  bottomLeft: !isUser ? const Radius.circular(4) : null,
                ),
              ),
              child: Text(
                msg.text,
                style: TextStyle(
                  color: isUser ? Colors.white : Colors.black87,
                ),
              ),
            ),
            if (msg.suggestion != null && msg.suggestion!.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lightbulb_outline, size: 14),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        msg.suggestion!,
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator(PersonaTheme? persona) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: DesignTokens.spacing12),
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.spacing16,
          vertical: DesignTokens.spacing12,
        ),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: DesignTokens.spacing8),
            Text('Analyzing...', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea(PersonaTheme? persona) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacing16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Tell me how you\'re feeling...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.spacing16,
                    vertical: DesignTokens.spacing12,
                  ),
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: DesignTokens.spacing8),
            CircleAvatar(
              backgroundColor: persona?.primary ?? Colors.blue,
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white),
                onPressed: _isAnalyzing ? null : _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getMoodColor(String sentiment) {
    switch (sentiment) {
      case 'positive':
      case 'motivated':
        return Colors.green;
      case 'negative':
        return Colors.red;
      case 'stressed':
        return Colors.orange;
      case 'neutral':
      default:
        return Colors.blue;
    }
  }

  IconData _getMoodIcon(String sentiment) {
    switch (sentiment) {
      case 'positive':
        return Icons.sentiment_very_satisfied;
      case 'motivated':
        return Icons.local_fire_department;
      case 'negative':
        return Icons.sentiment_very_dissatisfied;
      case 'stressed':
        return Icons.psychology;
      case 'neutral':
      default:
        return Icons.sentiment_neutral;
    }
  }

  void _showMoodHistory() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(DesignTokens.spacing16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Mood History',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: DesignTokens.spacing12),
            ..._messages
                .where((m) => !m.isUser && m.moodScore != null)
                .map((m) => ListTile(
                      leading: Icon(_getMoodIcon(m.sentiment)),
                      title: Text(m.text),
                      subtitle: Text('Score: ${m.moodScore}/10'),
                    )),
          ],
        ),
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;
  final String sentiment;
  final String? suggestion;
  final int? moodScore;

  _ChatMessage({
    required this.text,
    required this.isUser,
    this.sentiment = 'neutral',
    this.suggestion,
    this.moodScore,
  });
}
