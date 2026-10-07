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
    int? tzOffsetMinutes,
  }) =>
      postJson('/agent/focus/schedule', {
        'start_time': startTime,
        'duration_minutes': durationMinutes,
        'label': label,
        // M9: send the device's UTC offset so the backend interprets
        // startTime on the user's clock, not the server's UTC clock
        'tz_offset_minutes':
            tzOffsetMinutes ?? DateTime.now().timeZoneOffset.inMinutes,
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

  /// M11 step 1: propose a change and receive a short-lived approval token.
  /// Show the change to the user, then call [updateAgentDeviceSetting].
  Future<Map<String, dynamic>> proposeAgentDeviceSetting({
    required String setting,
    required dynamic value,
  }) =>
      postJson('/agent/device/settings/propose', {
        'setting': setting,
        'value': value,
      });

  /// M11 step 2: apply the change with the server-issued approval token
  /// (replaces the old client-asserted `user_approved` boolean).
  Future<Map<String, dynamic>> updateAgentDeviceSetting({
    required String setting,
    required dynamic value,
    required String approvalToken,
  }) =>
      postJson('/agent/device/settings', {
        'setting': setting,
        'value': value,
        'approval_token': approvalToken,
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

  /// M14: [state] is the CSRF state returned by [startAgentSocialOAuth] —
  /// the backend verifies it and consumes it (single-use).
  Future<Map<String, dynamic>> connectAgentSocialAccount({
    required String platform,
    required String accountId,
    required String state,
  }) =>
      postJson('/agent/social/connect', {
        'platform': platform,
        'account_id': accountId,
        'state': state,
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
