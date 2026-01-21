import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../models/app_info.dart';
import '../services/native_service.dart';
import '../services/storage_service.dart';

class AppStateProvider with ChangeNotifier {
  List<AppInfo> _installedApps = [];
  List<String> _blockedApps = [];
  String? _registeredTagId;
  bool _isBlockingEnabled = false;
  bool _isLoading = true;

  // Permission states
  bool _isNfcAvailable = false;
  bool _isNfcEnabled = false;
  bool _isAccessibilityEnabled = false;
  bool _isOverlayPermissionGranted = false;

  List<AppInfo> get installedApps => _installedApps;
  List<String> get blockedApps => _blockedApps;
  String? get registeredTagId => _registeredTagId;
  bool get isBlockingEnabled => _isBlockingEnabled;
  bool get isLoading => _isLoading;

  bool get isNfcAvailable => _isNfcAvailable;
  bool get isNfcEnabled => _isNfcEnabled;
  bool get isAccessibilityEnabled => _isAccessibilityEnabled;
  bool get isOverlayPermissionGranted => _isOverlayPermissionGranted;

  bool get isSetupComplete =>
      _registeredTagId != null &&
      _isAccessibilityEnabled &&
      _isOverlayPermissionGranted &&
      _blockedApps.isNotEmpty;

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    await _loadPermissionStates();
    await _loadBlockedApps();
    await _loadInstalledApps();
    _registeredTagId = StorageService.getRegisteredTagId();
    _isBlockingEnabled = await NativeService.isBlockingEnabled();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadPermissionStates() async {
    _isNfcAvailable = await NativeService.isNfcAvailable();
    _isNfcEnabled = await NativeService.isNfcEnabled();
    _isAccessibilityEnabled = await NativeService.isAccessibilityServiceEnabled();
    _isOverlayPermissionGranted = await NativeService.isOverlayPermissionGranted();
  }

  Future<void> refreshPermissionStates() async {
    await _loadPermissionStates();
    // Also refresh blocking enabled state (may have changed from lock screen)
    _isBlockingEnabled = await NativeService.isBlockingEnabled();
    notifyListeners();
  }

  Future<void> _loadBlockedApps() async {
    _blockedApps = StorageService.getBlockedApps();
  }

  Future<void> _loadInstalledApps() async {
    final apps = await NativeService.getInstalledApps();

    _installedApps = apps.map((app) {
      Uint8List? iconBytes;
      if (app['icon'] != null) {
        try {
          iconBytes = base64Decode(app['icon'] as String);
        } catch (e) {
          iconBytes = null;
        }
      }

      return AppInfo(
        packageName: app['packageName'] as String,
        appName: app['appName'] as String,
        icon: iconBytes,
        isBlocked: _blockedApps.contains(app['packageName']),
      );
    }).toList();

    _installedApps.sort((a, b) => a.appName.toLowerCase().compareTo(b.appName.toLowerCase()));
  }

  Future<void> toggleAppBlocked(String packageName) async {
    final index = _installedApps.indexWhere((app) => app.packageName == packageName);
    if (index != -1) {
      _installedApps[index].isBlocked = !_installedApps[index].isBlocked;

      if (_installedApps[index].isBlocked) {
        _blockedApps.add(packageName);
      } else {
        _blockedApps.remove(packageName);
      }

      await StorageService.setBlockedApps(_blockedApps);
      await NativeService.setBlockedApps(_blockedApps);
      notifyListeners();
    }
  }

  Future<void> registerNfcTag(String tagId) async {
    _registeredTagId = tagId;
    await StorageService.setRegisteredTagId(tagId);
    await NativeService.setRegisteredNfcTagId(tagId);
    notifyListeners();
  }

  Future<void> clearRegisteredTag() async {
    _registeredTagId = null;
    await StorageService.setRegisteredTagId(null);
    await NativeService.setRegisteredNfcTagId(null);
    notifyListeners();
  }

  Future<void> setBlockingEnabled(bool enabled) async {
    _isBlockingEnabled = enabled;
    await NativeService.setBlockingEnabled(enabled);
    notifyListeners();
  }

  Future<void> openNfcSettings() async {
    await NativeService.openNfcSettings();
  }

  Future<void> openAccessibilitySettings() async {
    await NativeService.openAccessibilitySettings();
  }

  Future<void> requestOverlayPermission() async {
    await NativeService.requestOverlayPermission();
  }
}
