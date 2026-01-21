import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const _keyBlockedApps = 'blocked_apps';
  static const _keySetupComplete = 'setup_complete';
  static const _keyRegisteredTagId = 'registered_tag_id';

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
}
