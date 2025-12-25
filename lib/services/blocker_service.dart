import 'package:flutter/services.dart';

class BlockerService {
  static const MethodChannel _channel = MethodChannel('com.rhodesai.totalcontrol/blocker');

  // Check if required permissions are granted
  Future<Map<String, bool>> checkPermissions() async {
    try {
      final result = await _channel.invokeMethod<Map>('checkPermissions');
      return {
        'accessibility': result?['accessibility'] ?? false,
        'overlay': result?['overlay'] ?? false,
        'vpn': result?['vpn'] ?? false,
      };
    } on PlatformException catch (e) {
      print('Platform exception: ${e.message}');
      return {'accessibility': true, 'overlay': true, 'vpn': false};
    } on MissingPluginException {
      return {'accessibility': true, 'overlay': true, 'vpn': false};
    }
  }

  // Open accessibility settings
  Future<void> openAccessibilitySettings() async {
    try {
      await _channel.invokeMethod('openAccessibilitySettings');
    } on PlatformException catch (e) {
      print('Could not open accessibility settings: ${e.message}');
    } on MissingPluginException {
      print('Accessibility settings not available on this platform');
    }
  }

  // Open overlay permission settings
  Future<void> openOverlaySettings() async {
    try {
      await _channel.invokeMethod('openOverlaySettings');
    } on PlatformException catch (e) {
      print('Could not open overlay settings: ${e.message}');
    } on MissingPluginException {
      print('Overlay settings not available on this platform');
    }
  }

  // === VPN CONTROLS (Freedom-style DNS blocking) ===

  // Prepare VPN - requests permission from user
  Future<bool> prepareVpn() async {
    try {
      final result = await _channel.invokeMethod<bool>('prepareVpn');
      return result ?? false;
    } on PlatformException catch (e) {
      print('Could not prepare VPN: ${e.message}');
      return false;
    } on MissingPluginException {
      print('VPN not available on this platform');
      return false;
    }
  }

  // Start VPN service
  Future<bool> startVpn() async {
    try {
      final result = await _channel.invokeMethod<bool>('startVpn');
      return result ?? false;
    } on PlatformException catch (e) {
      print('Could not start VPN: ${e.message}');
      return false;
    } on MissingPluginException {
      print('VPN not available on this platform');
      return false;
    }
  }

  // Stop VPN service
  Future<bool> stopVpn() async {
    try {
      final result = await _channel.invokeMethod<bool>('stopVpn');
      return result ?? false;
    } on PlatformException catch (e) {
      print('Could not stop VPN: ${e.message}');
      return false;
    } on MissingPluginException {
      print('VPN not available on this platform');
      return false;
    }
  }

  // Check if VPN is running
  Future<bool> isVpnRunning() async {
    try {
      final result = await _channel.invokeMethod<bool>('isVpnRunning');
      return result ?? false;
    } on PlatformException catch (e) {
      print('Could not check VPN status: ${e.message}');
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  // === LEGACY METHODS (AccessibilityService control) ===

  Future<void> startService() async {
    try {
      await _channel.invokeMethod('startService');
    } on PlatformException catch (e) {
      print('Could not start service: ${e.message}');
    } on MissingPluginException {
      print('Blocker service not available on this platform');
    }
  }

  Future<void> stopService() async {
    try {
      await _channel.invokeMethod('stopService');
    } on PlatformException catch (e) {
      print('Could not stop service: ${e.message}');
    } on MissingPluginException {
      print('Blocker service not available on this platform');
    }
  }

  Future<void> showBlockingOverlay(String reason) async {
    try {
      await _channel.invokeMethod('showBlockingOverlay', {'reason': reason});
    } on PlatformException catch (e) {
      print('Could not show overlay: ${e.message}');
    } on MissingPluginException {
      print('Overlay not available on this platform');
    }
  }

  Future<void> hideBlockingOverlay() async {
    try {
      await _channel.invokeMethod('hideBlockingOverlay');
    } on PlatformException catch (e) {
      print('Could not hide overlay: ${e.message}');
    } on MissingPluginException {
      print('Overlay not available on this platform');
    }
  }
}
