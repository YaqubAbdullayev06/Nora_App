import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../services/agent_api.dart';

/// Manages AI agent capabilities, social platform integration, and device settings.
class AgentProvider extends ChangeNotifier {
  final ApiService _api;

  AgentProvider({ApiService? api}) : _api = api ?? ApiService();

  Future<Map<String, dynamic>> getAgentCapabilities() {
    return _api.getAgentCapabilities();
  }

  Future<Map<String, dynamic>> getAgentFocusStatus() {
    return _api.getAgentFocusStatus();
  }

  Future<Map<String, dynamic>> scheduleAgentFocus({
    required String startTime,
    required int durationMinutes,
    String label = 'Focus session',
    int? tzOffsetMinutes,
  }) {
    return _api.scheduleAgentFocus(
      startTime: startTime,
      durationMinutes: durationMinutes,
      label: label,
      tzOffsetMinutes: tzOffsetMinutes,
    );
  }

  Future<Map<String, dynamic>> startAgentFocus({
    required int durationMinutes,
    String label = 'Focus session',
  }) {
    return _api.startAgentFocus(durationMinutes: durationMinutes, label: label);
  }

  Future<Map<String, dynamic>> stopAgentFocus() {
    return _api.stopAgentFocus();
  }

  Future<Map<String, dynamic>> readAgentDeviceSetting(String setting) {
    return _api.readAgentDeviceSetting(setting);
  }

  /// M11 step 1: propose a setting change, get a short-lived approval token.
  Future<Map<String, dynamic>> proposeAgentDeviceSetting({
    required String setting,
    required dynamic value,
  }) {
    return _api.proposeAgentDeviceSetting(setting: setting, value: value);
  }

  /// M11 step 2: apply the change with the server-issued approval token.
  Future<Map<String, dynamic>> updateAgentDeviceSetting({
    required String setting,
    required dynamic value,
    required String approvalToken,
  }) {
    return _api.updateAgentDeviceSetting(
      setting: setting,
      value: value,
      approvalToken: approvalToken,
    );
  }

  Future<Map<String, dynamic>> getAgentSocialPlatforms() {
    return _api.getAgentSocialPlatforms();
  }

  Future<Map<String, dynamic>> startAgentSocialOAuth({
    required String platform,
    required String redirectUri,
  }) {
    return _api.startAgentSocialOAuth(
      platform: platform,
      redirectUri: redirectUri,
    );
  }

  /// M14: [state] comes from [startAgentSocialOAuth] (single-use CSRF token).
  Future<Map<String, dynamic>> connectAgentSocialAccount({
    required String platform,
    required String accountId,
    required String state,
  }) {
    return _api.connectAgentSocialAccount(
      platform: platform,
      accountId: accountId,
      state: state,
    );
  }

  Future<Map<String, dynamic>> postAgentSocialContent({
    required String platform,
    required String accountId,
    required String text,
  }) {
    return _api.postAgentSocialContent(
      platform: platform,
      accountId: accountId,
      text: text,
    );
  }
}
