import 'package:flutter/services.dart';

class NativeService {
  static const _channel = MethodChannel('com.friedn.friedn/native');
  static Function(String tagId)? _onNfcTagScanned;

  static void init() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onNfcTagScanned') {
        final tagId = call.arguments['tagId'] as String?;
        if (tagId != null && _onNfcTagScanned != null) {
          _onNfcTagScanned!(tagId);
        }
      }
    });
  }

  static void setNfcTagScannedCallback(Function(String tagId)? callback) {
    _onNfcTagScanned = callback;
  }

  static Future<bool> isNfcAvailable() async {
    try {
      return await _channel.invokeMethod('isNfcAvailable') ?? false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> isNfcEnabled() async {
    try {
      return await _channel.invokeMethod('isNfcEnabled') ?? false;
    } catch (e) {
      return false;
    }
  }

  static Future<void> openNfcSettings() async {
    await _channel.invokeMethod('openNfcSettings');
  }

  static Future<bool> isAccessibilityServiceEnabled() async {
    try {
      return await _channel.invokeMethod('isAccessibilityServiceEnabled') ?? false;
    } catch (e) {
      return false;
    }
  }

  static Future<void> openAccessibilitySettings() async {
    await _channel.invokeMethod('openAccessibilitySettings');
  }

  static Future<bool> isOverlayPermissionGranted() async {
    try {
      return await _channel.invokeMethod('isOverlayPermissionGranted') ?? false;
    } catch (e) {
      return false;
    }
  }

  static Future<void> requestOverlayPermission() async {
    await _channel.invokeMethod('requestOverlayPermission');
  }

  static Future<bool> hasUsageStatsPermission() async {
    try {
      return await _channel.invokeMethod('hasUsageStatsPermission') ?? false;
    } catch (e) {
      return false;
    }
  }

  static Future<void> requestUsageStatsPermission() async {
    await _channel.invokeMethod('requestUsageStatsPermission');
  }

  static Future<void> setBlockedApps(List<String> apps) async {
    await _channel.invokeMethod('setBlockedApps', {'apps': apps});
  }

  static Future<void> setBlockingEnabled(bool enabled) async {
    await _channel.invokeMethod('setBlockingEnabled', {'enabled': enabled});
  }

  static Future<bool> isBlockingEnabled() async {
    try {
      return await _channel.invokeMethod('isBlockingEnabled') ?? false;
    } catch (e) {
      return false;
    }
  }

  static Future<void> setRegisteredNfcTagId(String? tagId) async {
    await _channel.invokeMethod('setRegisteredNfcTagId', {'tagId': tagId});
  }

  static Future<String?> getRegisteredNfcTagId() async {
    try {
      return await _channel.invokeMethod('getRegisteredNfcTagId');
    } catch (e) {
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getInstalledApps() async {
    try {
      final result = await _channel.invokeMethod('getInstalledApps');
      if (result == null) return [];
      return (result as List).map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<String?> getPendingNfcTagId() async {
    try {
      return await _channel.invokeMethod('getPendingNfcTagId');
    } catch (e) {
      return null;
    }
  }
}
