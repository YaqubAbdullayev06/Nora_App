import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/design_tokens.dart';
import '../../../providers/app_provider.dart';
import '../../../services/llm_service.dart';

/// Chat Screen — talk to Nora AI.
/// Uses Ollama local LLM with age-group personalities.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _llmService = LlmService();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkBackend();
    _addWelcomeMessage();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addWelcomeMessage() {
    final provider = context.read<AppProvider>();
    final persona = provider.persona;
    setState(() {
      _messages.add(ChatMessage(
        role: 'assistant',
        content: "Hi! I'm ${persona.mascotName} ${persona.mascotEmoji}\n\n"
            '${persona.tagline}\n\n'
            'Ask me anything!',
      ));
    });
  }

  Future<void> _checkBackend() async {
    final available = await _llmService.isAvailable();
    setState(() => _isAvailable = available);
    if (!available && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              'Ollama not running. Start it with: ollama serve'),
          backgroundColor: DesignTokens.warning,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    final provider = context.read<AppProvider>();
    final ageGroup = provider.ageGroup.name;

    setState(() {
      _messages.add(ChatMessage(role: 'user', content: text));
      _isLoading = true;
      _controller.clear();
    });

    _scrollToBottom();

    // Build conversation history (last 10 messages for context)
    final history = _messages.length > 2
        ? _messages.sublist(0, _messages.length - 1).takeLast(10).toList()
        : <ChatMessage>[];

    final response = await _llmService.sendMessage(
      message: text,
      ageGroup: ageGroup,
      conversationHistory: history,
    );

    setState(() {
      _messages.add(ChatMessage(
        role: 'assistant',
        content: response.error
            ? '${response.response}\n\n(Nora runs on ${response.model})'
            : response.response,
      ));
      _isLoading = false;
    });

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final persona = provider.persona;

        return Scaffold(
          backgroundColor: DesignTokens.background,
          appBar: AppBar(
            backgroundColor: DesignTokens.surface,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_rounded, color: DesignTokens.textPrimary),
              onPressed: () => Navigator.pop(context),
            ),
            title: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: persona.primary.withValues(alpha: 0.2),
                  child: Text(
                    persona.mascotEmoji,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      persona.mascotName,
                      style: TextStyle(
                        color: DesignTokens.textPrimary,
                        fontSize: DesignTokens.fontSizeBody,
                        fontWeight: DesignTokens.fontWeightSemiBold,
                      ),
                    ),
                    Text(
                      _isAvailable ? 'Powered by Ollama' : 'Offline mode',
                      style: TextStyle(
                        color: _isAvailable ? DesignTokens.success : DesignTokens.warning,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.refresh_rounded, color: DesignTokens.textMuted),
                onPressed: _checkBackend,
                tooltip: 'Check connection',
              ),
            ],
          ),
          body: Column(
            children: [
              // Messages
              Expanded(
                child: _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(persona.mascotEmoji,
                                style: const TextStyle(fontSize: 48)),
                            const SizedBox(height: 16),
                            Text(
                              'Ask me anything!',
                              style: TextStyle(
                                color: DesignTokens.textMuted,
                                fontSize: DesignTokens.fontSizeBody,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final isUser = msg.role == 'user';
                          return _buildMessage(msg, isUser, persona);
                        },
                      ),
              ),
              // Loading indicator
              if (_isLoading)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(persona.primary),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${persona.mascotName} is thinking...',
                        style: TextStyle(
                          color: DesignTokens.textMuted,
                          fontSize: DesignTokens.fontSizeCaption,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              // Input
              _buildInput(persona),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMessage(ChatMessage msg, bool isUser, dynamic persona) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        child: Row(
          mainAxisAlignment:
              isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser) ...[
              CircleAvatar(
                radius: 14,
                backgroundColor: persona.primary.withValues(alpha: 0.2),
                child: Text(persona.mascotEmoji,
                    style: const TextStyle(fontSize: 12)),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isUser ? persona.primary : DesignTokens.surface,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: Radius.circular(isUser ? 20 : 4),
                    bottomRight: Radius.circular(isUser ? 4 : 20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isUser ? persona.primary : Colors.black)
                          .withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  msg.content,
                  style: TextStyle(
                    color: isUser ? Colors.white : DesignTokens.textPrimary,
                    fontSize: DesignTokens.fontSizeBody,
                    height: 1.5,
                  ),
                ),
              ),
            ),
            if (isUser) ...[
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 14,
                backgroundColor: DesignTokens.accent.withValues(alpha: 0.2),
                child: Icon(Icons.person_rounded,
                    size: 14, color: DesignTokens.accent),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInput(dynamic persona) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DesignTokens.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: DesignTokens.background,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: DesignTokens.border),
                ),
                child: TextField(
                  controller: _controller,
                  style: TextStyle(
                    color: DesignTokens.textPrimary,
                    fontSize: DesignTokens.fontSizeBody,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Ask ${persona.mascotName}...',
                    hintStyle: TextStyle(color: DesignTokens.textMuted),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                  textInputAction: TextInputAction.send,
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _isLoading ? null : _sendMessage,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [persona.primary, persona.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: persona.primary.withValues(alpha: 0.4),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Extension to get last N items from a list.
extension _ListTakeLast<T> on List<T> {
  List<T> takeLast(int n) {
    if (length <= n) return this;
    return sublist(length - n);
  }
}
