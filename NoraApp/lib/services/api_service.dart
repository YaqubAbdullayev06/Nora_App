import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/config/env_config.dart';
import '../models/models.dart';
import 'auth_storage.dart';

/// API Service for Nora backend
/// Handles all HTTP communication with FastAPI backend.
///
/// SECURITY: Tokens are stored in FlutterSecureStorage (keychain/encrypted),
/// never in plaintext SharedPreferences. Access tokens auto-refresh on 401.
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  late final String baseUrl = EnvConfig.instance.backendUrl;
  String? _token;
  String? _refreshToken;
  final AuthStorage _authStorage = AuthStorage();
  bool _isRefreshing = false;

  /// Initialize from secure storage on app start.
  Future<void> init() async {
    _token = await _authStorage.getAccessToken();
    _refreshToken = await _authStorage.getRefreshToken();
  }

  /// Set auth token
  void setToken(String? token) {
    _token = token;
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  // ─── Auto-Refresh on 401 ───

  /// Make an authenticated request. On 401, tries refresh token before failing.
  /// Retries up to 2 times on network failures.
  Future<http.Response> _authenticatedRequest(
    Future<http.Response> Function(String token) request, {
    int maxRetries = 2,
  }) async {
    if (_token == null) {
      throw Exception('Not authenticated');
    }

    http.Response? response;
    Exception? lastException;

    for (var attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        response = await request(_token!);
        break; // Success, exit retry loop
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());
        if (attempt < maxRetries) {
          // Wait before retry (exponential backoff: 1s, 2s)
          await Future.delayed(Duration(seconds: attempt + 1));
        }
      }
    }

    if (response == null) {
      throw lastException ?? Exception('Network request failed');
    }

    if (response.statusCode == 401 && !_isRefreshing) {
      // Token expired — try refresh
      final refreshed = await _tryRefreshToken();
      if (refreshed) {
        response = await request(_token!);
      } else {
        // Refresh failed — clear stale tokens so UI forces re-login
        await clearAuth();
        throw Exception('Session expired. Please log in again.');
      }
    }

    return response;
  }

  Future<bool> _tryRefreshToken() async {
    if (_isRefreshing || _refreshToken == null) return false;
    _isRefreshing = true;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh_token': _refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _token = data['token'] as String;
        _refreshToken = data['refresh_token'] as String;
        await _authStorage.saveTokens(
          accessToken: _token!,
          refreshToken: _refreshToken!,
        );
        return true;
      } else {
        // Refresh failed (expired, reused, or revoked) — clear stale tokens
        await clearAuth();
        return false;
      }
    } catch (e) {
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  /// Clear auth state on logout or failed refresh.
  Future<void> clearAuth() async {
    _token = null;
    _refreshToken = null;
    await _authStorage.clearAll();
  }

  // ─── Health ───

  Future<bool> checkHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
        headers: _headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ─── Auth ───

  Future<Map<String, dynamic>> register({
    required String email,
    required String name,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: _headers,
      body: jsonEncode({
        'email': email,
        'name': name,
        'password': password,
      }),
    );
    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _token = data['token'];
      _refreshToken = data['refresh_token'];
      // Persist securely
      await _authStorage.saveAuthResponse(data);
      return data;
    }
    throw Exception(
        jsonDecode(response.body)['detail'] ?? 'Registration failed');
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: _headers,
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _token = data['token'];
      _refreshToken = data['refresh_token'];
      // Persist securely
      await _authStorage.saveAuthResponse(data);
      return data;
    }
    throw Exception(jsonDecode(response.body)['detail'] ?? 'Login failed');
  }

  /// Get current user profile from /auth/me.
  Future<Map<String, dynamic>> getMe() async {
    final response = await _authenticatedRequest(
      (token) => http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception(
        jsonDecode(response.body)['detail'] ?? 'Failed to get user profile');
  }

  // ─── Users ───

  Future<User> getUser(String userId) async {
    final response = await _authenticatedRequest(
      (token) => http.get(
        Uri.parse('$baseUrl/users/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ),
    );
    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to get user');
  }

  // ─── Focus Sessions ───

  Future<FocusSession> createSession(FocusSession session) async {
    final response = await http.post(
      Uri.parse('$baseUrl/sessions/'),
      headers: _headers,
      body: jsonEncode(session.toJson()),
    );
    if (response.statusCode == 201) {
      return FocusSession.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to create session');
  }

  Future<List<FocusSession>> getUserSessions(String userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/sessions/$userId'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((s) => FocusSession.fromJson(s)).toList();
    }
    throw Exception('Failed to get sessions');
  }

  Future<int> completeSession(String sessionId) async {
    final response = await http.put(
      Uri.parse('$baseUrl/sessions/$sessionId/complete'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['points_earned'] ?? 0;
    }
    throw Exception('Failed to complete session');
  }

  // ─── Content ───

  Future<List<ContentItem>> getContent({String? category}) async {
    final uri = category != null
        ? Uri.parse('$baseUrl/content/?category=$category')
        : Uri.parse('$baseUrl/content/');
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((c) => ContentItem.fromJson(c)).toList();
    }
    throw Exception('Failed to get content');
  }

  Future<ContentItem> createContent(ContentItem content) async {
    final response = await http.post(
      Uri.parse('$baseUrl/content/'),
      headers: _headers,
      body: jsonEncode(content.toJson()),
    );
    if (response.statusCode == 201) {
      return ContentItem.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to create content');
  }

  // ─── Recommendations ───

  Future<List<AIRecommendation>> getRecommendations(String userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/recommendations/$userId'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((r) => AIRecommendation.fromJson(r)).toList();
    }
    throw Exception('Failed to get recommendations');
  }

  // ─── Focus Score ───

  Future<FocusScore> getFocusScore(String userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/focus-score/$userId'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return FocusScore.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to get focus score');
  }

  // ─── Agent Capabilities ───

  Future<Map<String, dynamic>> getAgentCapabilities() async {
    return _getJson('/agent/capabilities');
  }

  Future<Map<String, dynamic>> getAgentFocusStatus() async {
    return _getJson('/agent/focus/status');
  }

  Future<Map<String, dynamic>> scheduleAgentFocus({
    required String startTime,
    required int durationMinutes,
    String label = 'Focus session',
  }) async {
    return _postJson('/agent/focus/schedule', {
      'start_time': startTime,
      'duration_minutes': durationMinutes,
      'label': label,
    });
  }

  Future<Map<String, dynamic>> startAgentFocus({
    required int durationMinutes,
    String label = 'Focus session',
  }) async {
    return _postJson('/agent/focus/start', {
      'duration_minutes': durationMinutes,
      'label': label,
    });
  }

  Future<Map<String, dynamic>> stopAgentFocus() async {
    return _postJson('/agent/focus/stop', {});
  }

  Future<Map<String, dynamic>> readAgentDeviceSetting(String setting) async {
    return _getJson('/agent/device/settings/$setting');
  }

  Future<Map<String, dynamic>> updateAgentDeviceSetting({
    required String setting,
    required dynamic value,
    required bool userApproved,
  }) async {
    return _postJson('/agent/device/settings', {
      'setting': setting,
      'value': value,
      'user_approved': userApproved,
    });
  }

  Future<Map<String, dynamic>> getAgentSocialPlatforms() async {
    return _getJson('/agent/social/platforms');
  }

  Future<Map<String, dynamic>> startAgentSocialOAuth({
    required String platform,
    required String redirectUri,
  }) async {
    return _postJson('/agent/social/oauth/start', {
      'platform': platform,
      'redirect_uri': redirectUri,
    });
  }

  Future<Map<String, dynamic>> connectAgentSocialAccount({
    required String platform,
    required String accountId,
  }) async {
    return _postJson('/agent/social/connect', {
      'platform': platform,
      'account_id': accountId,
    });
  }

  Future<Map<String, dynamic>> postAgentSocialContent({
    required String platform,
    required String accountId,
    required String text,
  }) async {
    return _postJson('/agent/social/post', {
      'platform': platform,
      'account_id': accountId,
      'text': text,
    });
  }

  Future<Map<String, dynamic>> _getJson(String path) async {
    final response = await _authenticatedRequest(
      (token) => http.get(
        Uri.parse('$baseUrl$path'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ),
    );
    return _decodeAgentResponse(response);
  }

  Future<Map<String, dynamic>> _postJson(
      String path, Map<String, dynamic> body) async {
    final response = await _authenticatedRequest(
      (token) => http.post(
        Uri.parse('$baseUrl$path'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      ),
    );
    return _decodeAgentResponse(response);
  }

  Map<String, dynamic> _decodeAgentResponse(http.Response response) {
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }
    throw Exception(
        decoded['detail'] ?? decoded['error'] ?? 'Agent request failed');
  }

  // ─── AI App Classification ───

  Future<Map<String, dynamic>> classifyApps({
    required List<Map<String, dynamic>> apps,
    String ageGroup = 'adult',
  }) async {
    return _postJson('/ai/classify-apps', {
      'apps': apps,
      'age_group': ageGroup,
    });
  }

  Future<Map<String, dynamic>> analyzeUsage({
    required Map<String, dynamic> usageData,
    String ageGroup = 'adult',
  }) async {
    return _postJson('/ai/analyze-usage', {
      'usage_data': usageData,
      'age_group': ageGroup,
    });
  }

  Future<Map<String, dynamic>> sendAICommand({
    required String command,
    String ageGroup = 'adult',
    Map<String, dynamic>? context,
    List<Map<String, dynamic>>? conversationHistory,
  }) async {
    return _postJson('/ai/command', {
      'command': command,
      'age_group': ageGroup,
      'context': context ?? {},
      'conversation_history': conversationHistory ?? [],
    });
  }

  Future<Map<String, dynamic>> decomposeTask(
    String task, {
    String ageGroup = 'adult',
  }) async {
    return _postJson('/ai/decompose-task', {
      'task': task,
      'age_group': ageGroup,
    });
  }

  // ─── Accountability Lock ───

  Future<Map<String, dynamic>> setupAccountabilityLock({
    required String pin,
    required String guardianName,
    int? lockDurationDays,
  }) async {
    return _postJson('/accountability/setup', {
      'pin': pin,
      'guardian_name': guardianName,
      'lock_duration_days': lockDurationDays,
    });
  }

  Future<Map<String, dynamic>> verifyAccountabilityLock({
    required String pin,
  }) async {
    return _postJson('/accountability/verify', {
      'pin': pin,
    });
  }

  Future<Map<String, dynamic>> getAccountabilityStatus() async {
    return _getJson('/accountability/status');
  }

  Future<Map<String, dynamic>> unlinkAccountabilityLock({
    required String pin,
  }) async {
    return _postJson('/accountability/unlink', {
      'pin': pin,
    });
  }

  // ─── Hard Cap ───

  Future<Map<String, dynamic>> setupHardCap({
    required int capMinutes,
    int softWarningPercent = 80,
    int hardWarningPercent = 90,
    bool requirePinToOverride = false,
  }) async {
    return _postJson('/hardcap/setup', {
      'cap_minutes': capMinutes,
      'soft_warning_percent': softWarningPercent,
      'hard_warning_percent': hardWarningPercent,
      'require_pin_to_override': requirePinToOverride,
    });
  }

  Future<Map<String, dynamic>> getHardCapStatus() async {
    return _getJson('/hardcap/status');
  }

  Future<Map<String, dynamic>> deactivateHardCap() async {
    return _postJson('/hardcap/deactivate', {});
  }

  // ─── Habits ───

  Future<Map<String, dynamic>> createHabit({
    required String name,
    String category = 'general',
    String icon = 'check_circle',
    String color = '#4CAF50',
    int screenTimeMinutes = 15,
    int targetPerDay = 1,
  }) async {
    return _postJson('/habits', {
      'name': name,
      'category': category,
      'icon': icon,
      'color': color,
      'screen_time_minutes': screenTimeMinutes,
      'target_per_day': targetPerDay,
    });
  }

  Future<Map<String, dynamic>> listHabits() async {
    return _getJson('/habits');
  }

  Future<Map<String, dynamic>> completeHabit({
    required int habitId,
    int durationMinutes = 0,
  }) async {
    return _postJson('/habits/complete', {
      'habit_id': habitId,
      'duration_minutes': durationMinutes,
    });
  }

  Future<Map<String, dynamic>> deleteHabit(int habitId) async {
    final response = await _authenticatedRequest(
      (token) => http.delete(
        Uri.parse('$baseUrl/habits/$habitId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ),
    );
    return _decodeAgentResponse(response);
  }

  Future<Map<String, dynamic>> getHabitStats() async {
    return _getJson('/habits/stats');
  }

  // ─── AI Notification Text ───

  /// Get AI-generated notification text from the backend LLM.
  Future<Map<String, dynamic>> getNotificationText({
    required String eventType,
    String ageGroup = 'adult',
    Map<String, dynamic>? context,
  }) async {
    return _postJson('/ai/notification-text', {
      'event_type': eventType,
      'age_group': ageGroup,
      'context': context ?? {},
    });
  }
}
