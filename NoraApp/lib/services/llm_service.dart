import 'dart:convert';
import 'package:http/http.dart' as http;

/// LLM Service — connects Nora Flutter app to local Ollama LLM via backend.
///
/// Flow: Flutter → Backend API → Ollama → Response
class LlmService {
  static const String baseUrl = 'http://192.168.0.101:8000';

  /// Send a chat message to Nora AI and get a response.
  ///
  /// [message] — the user's message
  /// [ageGroup] — current age group (baby/kid/teen/adult)
  /// [conversationHistory] — previous messages for context
  Future<LlmResponse> sendMessage({
    required String message,
    required String ageGroup,
    List<ChatMessage>? conversationHistory,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/ai/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message': message,
          'age_group': ageGroup,
          'conversation_history': conversationHistory
                  ?.map((m) => m.toJson())
                  .toList() ??
              [],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return LlmResponse(
          response: data['response'] ?? '',
          model: data['model'] ?? 'unknown',
        );
      } else {
        return LlmResponse(
          response: 'Sorry, I had trouble thinking. Please try again.',
          model: 'error',
          error: true,
        );
      }
    } catch (e) {
      return LlmResponse(
        response:
            'I can\'t reach my brain right now. Make sure Ollama is running.\n\nStart it with: ollama serve',
        model: 'offline',
        error: true,
      );
    }
  }

  /// Send a command to the AI Digital Assistant.
  /// The assistant can execute actions like scanning apps, blocking, etc.
  Future<AssistantResponse> sendCommand({
    required String command,
    required String ageGroup,
    Map<String, dynamic>? context,
    List<ChatMessage>? conversationHistory,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/ai/command'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'command': command,
          'age_group': ageGroup,
          'context': context ?? {},
          'conversation_history': conversationHistory
                  ?.map((m) => m.toJson())
                  .toList() ??
              [],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final actionsRaw = data['actions'] as List<dynamic>? ?? [];
        final actions = actionsRaw
            .map((a) => AIAction.fromMap(Map<String, dynamic>.from(a)))
            .toList();

        return AssistantResponse(
          response: data['response'] ?? '',
          model: data['model'] ?? 'unknown',
          actions: actions,
        );
      } else {
        return AssistantResponse(
          response: 'Sorry, I had trouble processing that.',
          model: 'error',
          actions: [],
          error: true,
        );
      }
    } catch (e) {
      return AssistantResponse(
        response:
            'I can\'t reach my brain right now. Make sure Ollama is running.',
        model: 'offline',
        actions: [],
        error: true,
      );
    }
  }

  /// Check if Ollama backend is running.
  Future<bool> isAvailable() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/ai/health'),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['ollama_running'] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}

/// A single chat message.
class ChatMessage {
  final String role; // 'user' or 'assistant'
  final String content;

  const ChatMessage({required this.role, required this.content});

  Map<String, dynamic> toJson() => {'role': role, 'content': content};

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        role: json['role'] ?? 'user',
        content: json['content'] ?? '',
      );
}

/// LLM response from Nora AI.
class LlmResponse {
  final String response;
  final String model;
  final bool error;

  const LlmResponse({
    required this.response,
    required this.model,
    this.error = false,
  });
}

/// AI Action parsed from assistant response.
class AIAction {
  final String type;
  final String description;
  final Map<String, dynamic> data;

  const AIAction({
    required this.type,
    required this.description,
    this.data = const {},
  });

  factory AIAction.fromMap(Map<String, dynamic> map) {
    return AIAction(
      type: map['action'] ?? map['type'] ?? 'unknown',
      description: map['description'] ?? '',
      data: Map<String, dynamic>.from(map)..remove('action')..remove('type')..remove('description'),
    );
  }
}

/// Response from the AI Digital Assistant.
class AssistantResponse {
  final String response;
  final String model;
  final List<AIAction> actions;
  final bool error;

  const AssistantResponse({
    required this.response,
    required this.model,
    required this.actions,
    this.error = false,
  });

  bool get hasActions => actions.isNotEmpty;
}
