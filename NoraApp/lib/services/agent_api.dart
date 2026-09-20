import 'api_service.dart';

/// Agent-related API methods extracted from ApiService.
/// Delegates HTTP calls to the core ApiService helpers.
extension AgentApi on ApiService {
  // ─── Agent Capabilities ───

  Future<Map<String, dynamic>> getAgentCapabilities() =>
      getJson('/agent/capabilities');

  Future<Map<String, dynamic>> getAgentFocusStatus() =>
      getJson('/agent/focus/status');

  Future<Map<String, dynamic>> scheduleAgentFocus({
    required String startTime,
    required int durationMinutes,
    String label = 'Focus session',
  }) =>
      postJson('/agent/focus/schedule', {
        'start_time': startTime,
        'duration_minutes': durationMinutes,
        'label': label,
      });

  Future<Map<String, dynamic>> startAgentFocus({
    required int durationMinutes,
    String label = 'Focus session',
  }) =>
      postJson('/agent/focus/start', {
        'duration_minutes': durationMinutes,
        'label': label,
      });

  Future<Map<String, dynamic>> stopAgentFocus() =>
      postJson('/agent/focus/stop', {});

  // ─── Agent Device Settings ───

  Future<Map<String, dynamic>> readAgentDeviceSetting(String setting) =>
      getJson('/agent/device/settings/$setting');

  Future<Map<String, dynamic>> updateAgentDeviceSetting({
    required String setting,
    required dynamic value,
    required bool userApproved,
  }) =>
      postJson('/agent/device/settings', {
        'setting': setting,
        'value': value,
        'user_approved': userApproved,
      });

  // ─── Agent Social ───

  Future<Map<String, dynamic>> getAgentSocialPlatforms() =>
      getJson('/agent/social/platforms');

  Future<Map<String, dynamic>> startAgentSocialOAuth({
    required String platform,
    required String redirectUri,
  }) =>
      postJson('/agent/social/oauth/start', {
        'platform': platform,
        'redirect_uri': redirectUri,
      });

  Future<Map<String, dynamic>> connectAgentSocialAccount({
    required String platform,
    required String accountId,
  }) =>
      postJson('/agent/social/connect', {
        'platform': platform,
        'account_id': accountId,
      });

  Future<Map<String, dynamic>> postAgentSocialContent({
    required String platform,
    required String accountId,
    required String text,
  }) =>
      postJson('/agent/social/post', {
        'platform': platform,
        'account_id': accountId,
        'text': text,
      });
}
