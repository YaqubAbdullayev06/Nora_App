import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure storage for JWT tokens and user credentials.
///
/// Replaces plaintext SharedPreferences storage.
/// Uses platform keychain (iOS) / encrypted shared preferences (Android).
///
/// SECURITY RULES:
/// - Access token: 15-minute lifetime, stored in keychain only
/// - Refresh token: 30-day lifetime, stored in keychain only
/// - Never write tokens to logs, debug output, or plaintext files
/// - On 401 from API → try refresh → if refresh fails → force logout
class AuthStorage {
  static const _accessTokenKey = 'nora_access_token';
  static const _refreshTokenKey = 'nora_refresh_token';
  static const _userIdKey = 'nora_user_id';
  static const _userEmailKey = 'nora_user_email';
  static const _userNameKey = 'nora_user_name';
  static const _personaKey = 'nora_persona';

  final FlutterSecureStorage _storage;

  AuthStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  // ─── Token Management ───

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  Future<String?> getAccessToken() async {
    return _storage.read(key: _accessTokenKey);
  }

  Future<String?> getRefreshToken() async {
    return _storage.read(key: _refreshTokenKey);
  }

  Future<void> clearTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }

  // ─── User Info ───

  Future<void> saveUserInfo({
    required String userId,
    required String email,
    String? name,
    String? persona,
  }) async {
    await _storage.write(key: _userIdKey, value: userId);
    await _storage.write(key: _userEmailKey, value: email);
    if (name != null) await _storage.write(key: _userNameKey, value: name);
    if (persona != null) await _storage.write(key: _personaKey, value: persona);
  }

  Future<String?> getUserId() async => _storage.read(key: _userIdKey);
  Future<String?> getUserEmail() async => _storage.read(key: _userEmailKey);
  Future<String?> getUserName() async => _storage.read(key: _userNameKey);
  Future<String?> getPersona() async => _storage.read(key: _personaKey);

  // ─── Full Auth State ───

  /// Check if user has stored tokens (auto-login eligible).
  Future<bool> hasValidSession() async {
    final token = await getAccessToken();
    final refresh = await getRefreshToken();
    return token != null && refresh != null;
  }

  /// Save full auth response from login/register.
  Future<void> saveAuthResponse(Map<String, dynamic> data) async {
    final user = data['user'] as Map<String, dynamic>?;
    await saveTokens(
      accessToken: data['token'] as String,
      refreshToken: data['refresh_token'] as String,
    );
    if (user != null) {
      await saveUserInfo(
        userId: user['id'].toString(),
        email: user['email'] as String? ?? '',
        name: user['name'] as String?,
        persona: user['persona'] as String?,
      );
    }
  }

  /// Clear everything on logout.
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
