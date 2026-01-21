import 'package:shared_preferences/shared_preferences.dart';
import '../models/blocking_session.dart';

class StorageService {
  static const _keyBlockedApps = 'blocked_apps';
  static const _keySetupComplete = 'setup_complete';
  static const _keyRegisteredTagId = 'registered_tag_id';
  static const _keyBlockingEndTime = 'blocking_end_time';
  static const _keyBlockingSessions = 'blocking_sessions';
  static const _keyCurrentSessionStart = 'current_session_start';

  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static List<String> getBlockedApps() {
    return _prefs.getStringList(_keyBlockedApps) ?? [];
  }

  static Future<void> setBlockedApps(List<String> apps) async {
    await _prefs.setStringList(_keyBlockedApps, apps);
  }

  static bool isSetupComplete() {
    return _prefs.getBool(_keySetupComplete) ?? false;
  }

  static Future<void> setSetupComplete(bool complete) async {
    await _prefs.setBool(_keySetupComplete, complete);
  }

  static String? getRegisteredTagId() {
    return _prefs.getString(_keyRegisteredTagId);
  }

  static Future<void> setRegisteredTagId(String? tagId) async {
    if (tagId == null) {
      await _prefs.remove(_keyRegisteredTagId);
    } else {
      await _prefs.setString(_keyRegisteredTagId, tagId);
    }
  }

  static int? getBlockingEndTime() {
    final value = _prefs.getInt(_keyBlockingEndTime);
    return value == 0 ? null : value;
  }

  static Future<void> setBlockingEndTime(int? endTimeMillis) async {
    if (endTimeMillis == null) {
      await _prefs.remove(_keyBlockingEndTime);
    } else {
      await _prefs.setInt(_keyBlockingEndTime, endTimeMillis);
    }
  }

  static List<BlockingSession> getBlockingSessions() {
    final jsonStr = _prefs.getString(_keyBlockingSessions);
    return BlockingSession.decodeList(jsonStr);
  }

  static Future<void> setBlockingSessions(List<BlockingSession> sessions) async {
    await _prefs.setString(_keyBlockingSessions, BlockingSession.encodeList(sessions));
  }

  static int? getCurrentSessionStart() {
    final value = _prefs.getInt(_keyCurrentSessionStart);
    return value == 0 ? null : value;
  }

  static Future<void> setCurrentSessionStart(int? startTimeMillis) async {
    if (startTimeMillis == null) {
      await _prefs.remove(_keyCurrentSessionStart);
    } else {
      await _prefs.setInt(_keyCurrentSessionStart, startTimeMillis);
    }
  }
}
