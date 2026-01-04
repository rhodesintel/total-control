import 'package:flutter/services.dart';

/// Service to check and request accessibility permission
class AccessibilityService {
  static const _channel = MethodChannel('com.rhodesai.totalcontrol/accessibility');

  static AccessibilityService? _instance;
  static AccessibilityService get instance => _instance ??= AccessibilityService._();

  AccessibilityService._();

  /// Check if accessibility service is enabled
  Future<bool> isEnabled() async {
    try {
      final result = await _channel.invokeMethod<bool>('isAccessibilityEnabled');
      return result ?? false;
    } catch (e) {
      print('Error checking accessibility: $e');
      return false;
    }
  }

  /// Open accessibility settings
  Future<void> openSettings() async {
    try {
      await _channel.invokeMethod('openAccessibilitySettings');
    } catch (e) {
      print('Error opening accessibility settings: $e');
    }
  }
}
