import 'dart:async';
import 'package:flutter/foundation.dart';
import 'api_service.dart';

/// Service to monitor network connectivity status.
/// Uses the API health endpoint to check if the backend is reachable.
/// Optimized: checks lazily on first getter access + periodic (5 min), NOT on construction.
class ConnectivityService extends ChangeNotifier {
  final ApiService _api = ApiService();

  bool _isConnected = true;
  bool _isChecking = false;
  Timer? _checkTimer;
  bool _isInitialized = false;

  bool get isConnected {
    if (!_isInitialized) Future.microtask(initialize); // defer side effects out of build
    return _isConnected;
  }
  bool get isChecking => _isChecking;

  /// Lazy init — starts periodic checks on first getter access.
  void initialize() {
    if (_isInitialized) return;
    _isInitialized = true;
    startChecking();
  }

  /// Start periodic connectivity checks — every 5 minutes (not 30s).
  void startChecking() {
    _checkTimer?.cancel();
    _checkTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      checkConnectivity();
    });
    // Initial check
    checkConnectivity();
  }

  /// Stop periodic connectivity checks.
  void stopChecking() {
    _checkTimer?.cancel();
    _checkTimer = null;
  }

  /// Check if the backend is reachable.
  Future<bool> checkConnectivity() async {
    if (_isChecking) return _isConnected;

    _isChecking = true;
    try {
      final wasConnected = _isConnected;
      _isConnected = await _api.checkHealth();

      // Notify listeners only if status changed
      if (wasConnected != _isConnected) {
        notifyListeners();
      }
    } catch (e) {
      _isConnected = false;
      notifyListeners();
    } finally {
      _isChecking = false;
    }
    return _isConnected;
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    super.dispose();
  }
}
