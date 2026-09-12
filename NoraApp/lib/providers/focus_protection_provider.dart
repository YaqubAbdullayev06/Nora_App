import 'package:flutter/foundation.dart';
import '../services/focus_protection_service.dart';

/// Wraps FocusProtectionService for use with Provider.
class FocusProtectionProvider extends ChangeNotifier {
  final FocusProtectionService _service = FocusProtectionService();

  Future<FocusProtectionStatus> requestAuthorization() {
    return _service.requestAuthorization();
  }

  Future<FocusProtectionStatus> getStatus() {
    return _service.getStatus();
  }

  Future<void> openSettings() {
    return _service.openSettings();
  }

  Future<FocusProtectionStatus> selectApps() {
    return _service.selectApps();
  }

  Future<FocusProtectionStatus> enableBlocking() {
    return _service.enableBlocking();
  }

  Future<FocusProtectionStatus> disableBlocking() {
    return _service.disableBlocking();
  }
}
