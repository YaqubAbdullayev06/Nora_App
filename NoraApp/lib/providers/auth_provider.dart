import 'package:flutter/foundation.dart';
import '../core/enums/age_group.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import 'persona_provider.dart';

/// Manages authentication state and user profile.
class AuthProvider extends ChangeNotifier {
  final ApiService _api;
  final PersonaProvider _personaProvider;

  User? _currentUser;
  bool _isLoading = false;
  String? _error;
  bool _isAppLocked = false;

  AuthProvider({
    required PersonaProvider personaProvider,
    ApiService? api,
  })  : _personaProvider = personaProvider,
        _api = api ?? ApiService();

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;
  bool get isAppLocked => _isAppLocked;

  /// Restore user session from stored token on app start.
  Future<void> initialize() async {
    try {
      final data = await _api.getMe();
      _currentUser = User.fromJson(data);
      _personaProvider.setAgeGroup(_currentUser!.ageGroup);
      notifyListeners();
    } catch (e) {
      // Token invalid or expired — user must log in
      _currentUser = null;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _api.login(email: email, password: password);
      _currentUser = User.fromJson(data['user']);
      _personaProvider.setAgeGroup(_currentUser!.ageGroup);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(
    String email,
    String name,
    String password, {
    AgeGroup ageGroup = AgeGroup.adult,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _api.register(
        email: email,
        name: name,
        password: password,
        ageGroup: ageGroup.name,
      );
      _currentUser = User.fromJson(data['user']);
      _personaProvider.setAgeGroup(ageGroup);
      _currentUser = _currentUser!.copyWith(ageGroup: ageGroup);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    _isAppLocked = false;
    _isLoading = false;
    _error = null;
    await _api.clearAuth();
    notifyListeners();
  }

  void lockApp() {
    if (_isAppLocked) return;
    _isAppLocked = true;
    notifyListeners();
  }

  void unlockApp() {
    if (!_isAppLocked) return;
    _isAppLocked = false;
    notifyListeners();
  }

  void updateProfile({required String name}) {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(name: name);
    } else {
      _currentUser = User(
        id: '1',
        email: 'explorer@nora.app',
        name: name,
        ageGroup: _personaProvider.ageGroup,
        createdAt: DateTime.now(),
      );
    }
    notifyListeners();
  }
}
