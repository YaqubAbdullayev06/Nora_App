import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/design_tokens.dart';
import '../../../providers/app_provider.dart';
import '../../../services/llm_service.dart';
import '../../../services/app_scanner_service.dart';
import '../../../services/usage_tracker_service.dart';
import '../../../services/api_service.dart';
import '../../../models/app_info.dart';

/// Digital Assistant Screen — AI-powered chat with device control.
/// The AI can scan apps, block distractions, analyze usage, and more.
class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _llmService = LlmService();
  final _scannerService = AppScannerService();
  final _usageService = UsageTrackerService();
  final _apiService = ApiService();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isAvailable = false;
  bool _isScanning = false;
  Map<String, dynamic>? _lastScanResults;
  UsageStatsSummary? _lastUsageSummary;

  bool _welcomeAdded = false;

  @override
  void initState() {
    super.initState();
    _checkBackend();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_welcomeAdded) {
      _welcomeAdded = true;
      _addWelcomeMessage();
    }
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
        content: "Hey! I'm ${persona.mascotName} ${persona.mascotEmoji}\n\n"
            "I'm your AI digital assistant. I can:\n\n"
            "📱 Scan all your apps\n"
            "🚫 Block distracting apps\n"
            "📊 Track your screen time\n"
            "🎯 Start focus sessions\n"
            "💡 Give you productivity insights\n\n"
            'What would you like to do?',
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

    // Build context from device state
    final contextData = await _buildDeviceContext();

    // Build conversation history
    final history = _messages.length > 2
        ? _messages.sublist(0, _messages.length - 1).takeLast(10).toList()
        : <ChatMessage>[];

    // Send to AI assistant
    final response = await _llmService.sendCommand(
      command: text,
      ageGroup: ageGroup,
      context: contextData,
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

    // Execute any actions the AI requested
    if (response.hasActions) {
      await _executeActions(response.actions);
    }

    _scrollToBottom();
  }

  Future<Map<String, dynamic>> _buildDeviceContext() async {
    final context = <String, dynamic>{};

    // Add scan results if available
    if (_lastScanResults != null) {
      context['scan_results'] = _lastScanResults;
      context['installed_apps_count'] = _lastScanResults!['totalApps'] ?? 0;
    }

    // Add blocked apps
    try {
      final blocked = await _scannerService.getBlockedApps();
      context['blocked_apps'] = blocked;
    } catch (_) {}

    // Add usage data
    try {
      final todayUsage = await _usageService.getTodayUsage();
      if (todayUsage != null) {
        context['usage_today'] = {
          'totalScreenTimeMinutes': todayUsage.totalScreenTimeMinutes,
          'socialMediaMinutes': todayUsage.socialMediaMinutes,
        };
      }
    } catch (_) {}

    return context;
  }

  Future<void> _executeActions(List<AIAction> actions) async {
    for (final action in actions) {
      switch (action.type) {
        case 'scan_apps':
          await _performAppScan();
          break;
        case 'show_usage':
          await _showUsageStats();
          break;
        case 'show_recommendations':
          await _showRecommendations();
          break;
        case 'block_apps':
          final packages = action.data['packages'];
          if (packages is List && packages.isNotEmpty) {
            // SAFETY: Ask user confirmation before blocking
            final confirmed = await _confirmDestructiveAction(
              title: 'Block Apps',
              description: 'Block ${packages.length} apps during focus sessions?',
              packages: packages.cast<String>(),
            );
            if (confirmed) {
              await _blockApps(packages.cast<String>());
            } else {
              setState(() {
                _messages.add(ChatMessage(
                  role: 'assistant',
                  content: 'Okay, I won\'t block those apps. Let me know if you change your mind.',
                ));
              });
            }
          }
          break;
        case 'unblock_apps':
          final packages = action.data['packages'];
          if (packages is List && packages.isNotEmpty) {
            // SAFETY: Ask user confirmation before unblocking
            final confirmed = await _confirmDestructiveAction(
              title: 'Unblock Apps',
              description: 'Unblock ${packages.length} apps? These will be accessible again.',
              packages: packages.cast<String>(),
            );
            if (confirmed) {
              await _unblockApps(packages.cast<String>());
            } else {
              setState(() {
                _messages.add(ChatMessage(
                  role: 'assistant',
                  content: 'Okay, keeping those apps blocked.',
                ));
              });
            }
          }
          break;
        case 'start_focus':
          final minutes = action.data['minutes'] ?? 25;
          _startFocusSession(minutes);
          break;
      }
    }
  }

  /// Show confirmation dialog for destructive actions (block/unblock).
  /// Returns true if user confirmed, false if cancelled.
  Future<bool> _confirmDestructiveAction({
    required String title,
    required String description,
    required List<String> packages,
  }) async {
    final provider = context.read<AppProvider>();
    final persona = provider.persona;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: DesignTokens.surface,
        title: Text(title, style: TextStyle(color: DesignTokens.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(description, style: TextStyle(color: DesignTokens.textMuted)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: DesignTokens.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                packages.take(5).join('\n') + (packages.length > 5 ? '\n...and ${packages.length - 5} more' : ''),
                style: TextStyle(color: DesignTokens.textSecondary, fontSize: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: DesignTokens.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: persona.primary),
            child: Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  Future<void> _performAppScan() async {
    setState(() => _isScanning = true);

    try {
      // Scan all apps
      final apps = await _scannerService.scanAppsWithBlockStatus();

      // Get usage data
      final todayUsage = await _usageService.getTodayUsage();

      // Merge usage data with app list
      final appsWithUsage = apps.map((app) {
        final usageApp = todayUsage?.topApps.firstWhere(
          (u) => u.packageName == app.packageName,
          orElse: () => AppUsageEntry(
            packageName: app.packageName,
            appName: app.appName,
            totalTimeMinutes: 0,
            lastTimeUsed: 0,
            category: app.category,
          ),
        );
        return app.copyWith(
          usageTodayMinutes: usageApp?.totalTimeMinutes ?? 0,
        );
      }).toList();

      // Send to AI classifier
      final appMaps = appsWithUsage
          .where((a) => !a.isSystemApp)
          .map((a) => a.toMap())
          .toList();

      final provider = context.read<AppProvider>();
      final classification = await _apiService.classifyApps(
        apps: appMaps,
        ageGroup: provider.ageGroup.name,
      );

      setState(() {
        _lastScanResults = classification;
        _isScanning = false;
      });

      // Add scan results to chat
      final totalApps = classification['totalApps'] ?? 0;
      final distractionCount = classification['distractionAppsCount'] ?? 0;
      final blockingCount =
          (classification['aiRecommendedBlock'] as List?)?.length ?? 0;
      final summary = classification['summary'] ?? '';

      setState(() {
        _messages.add(ChatMessage(
          role: 'assistant',
          content: "📱 **App Scan Complete**\n\n"
              "$summary\n\n"
              "Found $distractionCount distraction apps. "
              "AI recommends blocking $blockingCount apps.\n\n"
              "Want me to apply the recommendations?",
        ));
      });
    } catch (e) {
      setState(() {
        _isScanning = false;
        _messages.add(ChatMessage(
          role: 'assistant',
          content: "Sorry, I had trouble scanning apps. Error: $e",
        ));
      });
    }

    _scrollToBottom();
  }

  Future<void> _showUsageStats() async {
    try {
      final todayUsage = await _usageService.getTodayUsage();
      if (todayUsage == null) {
        setState(() {
          _messages.add(ChatMessage(
            role: 'assistant',
            content:
                "I couldn't get usage data. Make sure Usage Access permission is enabled.",
          ));
        });
        _scrollToBottom();
        return;
      }

      final buffer = StringBuffer();
      buffer.writeln("📊 **Today's Usage Report**\n");
      buffer.writeln("Total screen time: ${todayUsage.totalScreenTimeDisplay}");
      buffer.writeln("Social media: ${todayUsage.socialMediaTimeDisplay}");
      buffer.writeln("Entertainment: ${todayUsage.entertainmentMinutes}m");
      buffer.writeln("Productivity: ${todayUsage.productivityMinutes}m");
      buffer.writeln("Apps used: ${todayUsage.appCount}");
      buffer.writeln("\n**Top Apps:**");

      for (final app in todayUsage.topApps.take(8)) {
        final emoji = _getCategoryEmoji(app.category);
        buffer.writeln("$emoji ${app.appName}: ${app.usageDisplay}");
      }

      setState(() {
        _messages.add(ChatMessage(
          role: 'assistant',
          content: buffer.toString(),
        ));
      });
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          role: 'assistant',
          content: "Sorry, I couldn't retrieve usage data.",
        ));
      });
    }

    _scrollToBottom();
  }

  Future<void> _showRecommendations() async {
    if (_lastScanResults == null) {
      setState(() {
        _messages.add(ChatMessage(
          role: 'assistant',
          content: "I need to scan your apps first. Want me to scan now?",
        ));
      });
      _scrollToBottom();
      return;
    }

    final recommendations = _lastScanResults!['aiRecommendedBlock'] as List? ?? [];
    if (recommendations.isEmpty) {
      setState(() {
        _messages.add(ChatMessage(
          role: 'assistant',
          content: "No apps recommended for blocking right now. You're doing great! 🎉",
        ));
      });
      _scrollToBottom();
      return;
    }

    final buffer = StringBuffer();
    buffer.writeln("🎯 **AI Blocking Recommendations**\n");

    for (final rec in recommendations) {
      buffer.writeln(
          "🚫 ${rec['appName']} (${rec['category']})\n   Reason: ${rec['reason']}");
    }

    buffer.writeln(
        "\nSay \"block recommended apps\" to apply all, or pick specific ones.");

    setState(() {
      _messages.add(ChatMessage(
        role: 'assistant',
        content: buffer.toString(),
      ));
    });

    _scrollToBottom();
  }

  Future<void> _blockApps(List<String> packages) async {
    try {
      await _scannerService.addToBlockedApps(packages);
      setState(() {
        _messages.add(ChatMessage(
          role: 'assistant',
          content:
              "✅ Blocked ${packages.length} apps. They'll be blocked during focus sessions.",
        ));
      });
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          role: 'assistant',
          content: "Sorry, I couldn't block those apps.",
        ));
      });
    }
    _scrollToBottom();
  }

  Future<void> _unblockApps(List<String> packages) async {
    try {
      await _scannerService.removeFromBlockedApps(packages);
      setState(() {
        _messages.add(ChatMessage(
          role: 'assistant',
          content: "✅ Unblocked ${packages.length} apps.",
        ));
      });
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          role: 'assistant',
          content: "Sorry, I couldn't unblock those apps.",
        ));
      });
    }
    _scrollToBottom();
  }

  void _startFocusSession(int minutes) {
    final provider = context.read<AppProvider>();
    provider.setTimerDuration(minutes);
    provider.startTimer();
    setState(() {
      _messages.add(ChatMessage(
        role: 'assistant',
        content:
            "🎯 Focus session started! $minutes minutes on the clock.\n\n"
            "Distracting apps are now blocked. You've got this!",
      ));
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
              icon: Icon(Icons.arrow_back_rounded,
                  color: DesignTokens.textPrimary),
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
                      '${persona.mascotName} Assistant',
                      style: TextStyle(
                        color: DesignTokens.textPrimary,
                        fontSize: DesignTokens.fontSizeBody,
                        fontWeight: DesignTokens.fontWeightSemiBold,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: _isAvailable
                                ? DesignTokens.success
                                : DesignTokens.warning,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _isAvailable ? 'AI Online' : 'Offline Mode',
                          style: TextStyle(
                            color: _isAvailable
                                ? DesignTokens.success
                                : DesignTokens.warning,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.phone_android_rounded,
                    color: DesignTokens.textMuted),
                onPressed: _isScanning ? null : _performAppScan,
                tooltip: 'Scan Apps',
              ),
              IconButton(
                icon: Icon(Icons.refresh_rounded, color: DesignTokens.textMuted),
                onPressed: _checkBackend,
                tooltip: 'Check connection',
              ),
            ],
          ),
          body: Column(
            children: [
              // Quick action chips
              _buildQuickActions(persona),
              // Messages
              Expanded(
                child: _messages.isEmpty
                    ? _buildEmptyState(persona)
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
              // Scanning indicator
              if (_isScanning)
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
                        'Scanning apps...',
                        style: TextStyle(
                          color: DesignTokens.textMuted,
                          fontSize: DesignTokens.fontSizeCaption,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              // Loading indicator
              if (_isLoading && !_isScanning)
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

  Widget _buildQuickActions(dynamic persona) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: DesignTokens.surface,
        border: Border(
          bottom: BorderSide(color: DesignTokens.border, width: 0.5),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildActionChip(
              icon: Icons.phone_android_rounded,
              label: 'Scan Apps',
              onTap: _isScanning ? null : _performAppScan,
              persona: persona,
            ),
            const SizedBox(width: 8),
            _buildActionChip(
              icon: Icons.analytics_rounded,
              label: 'Usage',
              onTap: _showUsageStats,
              persona: persona,
            ),
            const SizedBox(width: 8),
            _buildActionChip(
              icon: Icons.block_rounded,
              label: 'Block Apps',
              onTap: () => _sendMessageWithText('Show me apps to block'),
              persona: persona,
            ),
            const SizedBox(width: 8),
            _buildActionChip(
              icon: Icons.play_arrow_rounded,
              label: 'Focus',
              onTap: () => _sendMessageWithText('Start a 25 minute focus session'),
              persona: persona,
            ),
            const SizedBox(width: 8),
            _buildActionChip(
              icon: Icons.lightbulb_rounded,
              label: 'Tips',
              onTap: () => _sendMessageWithText('Give me productivity tips based on my usage'),
              persona: persona,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionChip({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    required dynamic persona,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: persona.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: persona.primary.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: persona.primary),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: persona.primary,
                fontSize: 12,
                fontWeight: DesignTokens.fontWeightMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessageWithText(String text) {
    _controller.text = text;
    _sendMessage();
  }

  Widget _buildEmptyState(dynamic persona) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(persona.mascotEmoji, style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text(
            'What can I help you with?',
            style: TextStyle(
              color: DesignTokens.textMuted,
              fontSize: DesignTokens.fontSizeBody,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try: "Scan my apps" or "Block social media"',
            style: TextStyle(
              color: DesignTokens.textMuted,
              fontSize: DesignTokens.fontSizeCaption,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(ChatMessage msg, bool isUser, dynamic persona) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                    hintText: 'Ask ${persona.mascotName} to do something...',
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
                child: const Icon(
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

  String _getCategoryEmoji(String category) {
    switch (category) {
      case 'social_media':
        return '📱';
      case 'entertainment':
        return '🎬';
      case 'games':
        return '🎮';
      case 'productivity':
        return '💼';
      case 'messaging':
        return '💬';
      case 'education':
        return '📚';
      default:
        return '📦';
    }
  }
}

/// Extension to get last N items from a list.
extension _ListTakeLast<T> on List<T> {
  List<T> takeLast(int n) {
    if (length <= n) return this;
    return sublist(length - n);
  }
}
