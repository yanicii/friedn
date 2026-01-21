import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../models/app_info.dart';
import '../models/blocking_session.dart';
import '../services/native_service.dart';
import '../services/storage_service.dart';

class AppStateProvider with ChangeNotifier {
  List<AppInfo> _installedApps = [];
  List<String> _blockedApps = [];
  String? _registeredTagId;
  bool _isBlockingEnabled = false;
  bool _isLoading = true;
  int? _blockingEndTime; // Unix timestamp in milliseconds
  Timer? _timerCheckTimer;

  // Stats tracking
  List<BlockingSession> _blockingSessions = [];
  int? _currentSessionStart;

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
  int? get blockingEndTime => _blockingEndTime;

  bool get isNfcAvailable => _isNfcAvailable;
  bool get isNfcEnabled => _isNfcEnabled;
  bool get isAccessibilityEnabled => _isAccessibilityEnabled;
  bool get isOverlayPermissionGranted => _isOverlayPermissionGranted;

  bool get hasActiveTimer =>
      _blockingEndTime != null &&
      _blockingEndTime! > DateTime.now().millisecondsSinceEpoch;

  Duration? get remainingTime {
    if (_blockingEndTime == null) return null;
    final remaining = _blockingEndTime! - DateTime.now().millisecondsSinceEpoch;
    if (remaining <= 0) return null;
    return Duration(milliseconds: remaining);
  }

  List<BlockingSession> get blockingSessions => _blockingSessions;

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
    _loadBlockingSessions();
    _registeredTagId = StorageService.getRegisteredTagId();
    _isBlockingEnabled = await NativeService.isBlockingEnabled();
    _blockingEndTime = await NativeService.getBlockingEndTime();

    // Start timer check if blocking is enabled with a timer
    if (_isBlockingEnabled && hasActiveTimer) {
      _startTimerCheck();
    }

    _isLoading = false;
    notifyListeners();
  }

  void _loadBlockingSessions() {
    _blockingSessions = StorageService.getBlockingSessions();
    _currentSessionStart = StorageService.getCurrentSessionStart();
  }

  void _startTimerCheck() {
    _timerCheckTimer?.cancel();
    _timerCheckTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _checkTimerExpired();
      notifyListeners(); // Update UI with remaining time
    });
  }

  void _stopTimerCheck() {
    _timerCheckTimer?.cancel();
    _timerCheckTimer = null;
  }

  Future<void> _checkTimerExpired() async {
    if (_blockingEndTime == null) return;
    if (DateTime.now().millisecondsSinceEpoch >= _blockingEndTime!) {
      // Timer expired, disable blocking
      await setBlockingEnabled(false);
      await clearBlockingEndTime();
    }
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
    _blockingEndTime = await NativeService.getBlockingEndTime();

    // Update timer check based on current state
    if (_isBlockingEnabled && hasActiveTimer) {
      if (_timerCheckTimer == null) {
        _startTimerCheck();
      }
    } else {
      _stopTimerCheck();
    }
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

  Future<void> selectAllApps() async {
    for (final app in _installedApps) {
      if (!app.isBlocked) {
        app.isBlocked = true;
        _blockedApps.add(app.packageName);
      }
    }
    await StorageService.setBlockedApps(_blockedApps);
    await NativeService.setBlockedApps(_blockedApps);
    notifyListeners();
  }

  Future<void> clearAllApps() async {
    for (final app in _installedApps) {
      app.isBlocked = false;
    }
    _blockedApps.clear();
    await StorageService.setBlockedApps(_blockedApps);
    await NativeService.setBlockedApps(_blockedApps);
    notifyListeners();
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
    if (enabled && !_isBlockingEnabled) {
      // Starting a new session
      await _startBlockingSession();
    } else if (!enabled && _isBlockingEnabled) {
      // Ending a session
      await _endBlockingSession();
    }

    _isBlockingEnabled = enabled;
    await NativeService.setBlockingEnabled(enabled);
    if (!enabled) {
      _stopTimerCheck();
      await clearBlockingEndTime();
    } else if (hasActiveTimer) {
      _startTimerCheck();
    }
    notifyListeners();
  }

  Future<void> setBlockingWithTimer(Duration duration) async {
    // Start a new session
    await _startBlockingSession();

    final endTime = DateTime.now().millisecondsSinceEpoch + duration.inMilliseconds;
    _blockingEndTime = endTime;
    await StorageService.setBlockingEndTime(endTime);
    await NativeService.setBlockingEndTime(endTime);
    _isBlockingEnabled = true;
    await NativeService.setBlockingEnabled(true);
    _startTimerCheck();
    notifyListeners();
  }

  Future<void> _startBlockingSession() async {
    _currentSessionStart = DateTime.now().millisecondsSinceEpoch;
    await StorageService.setCurrentSessionStart(_currentSessionStart);
  }

  Future<void> _endBlockingSession() async {
    if (_currentSessionStart != null) {
      final session = BlockingSession(
        startTime: _currentSessionStart!,
        endTime: DateTime.now().millisecondsSinceEpoch,
        blockedApps: List<String>.from(_blockedApps),
      );
      _blockingSessions.add(session);
      await StorageService.setBlockingSessions(_blockingSessions);
      _currentSessionStart = null;
      await StorageService.setCurrentSessionStart(null);
    }
  }

  Future<void> clearBlockingEndTime() async {
    _blockingEndTime = null;
    await StorageService.setBlockingEndTime(null);
    await NativeService.setBlockingEndTime(null);
    _stopTimerCheck();
    notifyListeners();
  }

  BlockingStats getBlockingStats() {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final weekStart = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1))
        .millisecondsSinceEpoch;

    int totalMinutes = 0;
    int weekMinutes = 0;
    int todayMinutes = 0;
    final appMinutes = <String, int>{};

    // Calculate from completed sessions
    for (final session in _blockingSessions) {
      final sessionMinutes = session.durationMinutes;
      totalMinutes += sessionMinutes;

      // Check if session overlaps with this week
      if (session.endTime != null && session.endTime! >= weekStart) {
        final effectiveStart = session.startTime < weekStart ? weekStart : session.startTime;
        final weekSessionMinutes = ((session.endTime! - effectiveStart) / 60000).floor();
        weekMinutes += weekSessionMinutes;
      }

      // Check if session overlaps with today
      if (session.endTime != null && session.endTime! >= todayStart) {
        final effectiveStart = session.startTime < todayStart ? todayStart : session.startTime;
        final todaySessionMinutes = ((session.endTime! - effectiveStart) / 60000).floor();
        todayMinutes += todaySessionMinutes;
      }

      // Track per-app minutes
      for (final packageName in session.blockedApps) {
        appMinutes[packageName] = (appMinutes[packageName] ?? 0) + sessionMinutes;
      }
    }

    // Add current active session if any
    if (_currentSessionStart != null) {
      final currentMinutes = ((now.millisecondsSinceEpoch - _currentSessionStart!) / 60000).floor();
      totalMinutes += currentMinutes;

      if (_currentSessionStart! >= weekStart) {
        weekMinutes += currentMinutes;
      } else {
        final weekSessionMinutes = ((now.millisecondsSinceEpoch - weekStart) / 60000).floor();
        weekMinutes += weekSessionMinutes;
      }

      if (_currentSessionStart! >= todayStart) {
        todayMinutes += currentMinutes;
      } else {
        final todaySessionMinutes = ((now.millisecondsSinceEpoch - todayStart) / 60000).floor();
        todayMinutes += todaySessionMinutes;
      }

      for (final packageName in _blockedApps) {
        appMinutes[packageName] = (appMinutes[packageName] ?? 0) + currentMinutes;
      }
    }

    // Get top 3 blocked apps
    final sortedApps = appMinutes.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topApps = sortedApps.take(3).map((e) {
      final appInfo = _installedApps.firstWhere(
        (app) => app.packageName == e.key,
        orElse: () => AppInfo(packageName: e.key, appName: e.key, icon: null, isBlocked: false),
      );
      return AppBlockStats(
        packageName: e.key,
        appName: appInfo.appName,
        totalMinutes: e.value,
      );
    }).toList();

    return BlockingStats(
      totalMinutes: totalMinutes,
      weekMinutes: weekMinutes,
      todayMinutes: todayMinutes,
      topBlockedApps: topApps,
    );
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
