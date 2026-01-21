import 'dart:convert';

class BlockingSession {
  final int startTime; // Unix timestamp in milliseconds
  final int? endTime; // Unix timestamp in milliseconds (null if still active)
  final List<String> blockedApps; // Package names of apps blocked during this session

  BlockingSession({
    required this.startTime,
    this.endTime,
    required this.blockedApps,
  });

  int get durationMinutes {
    final end = endTime ?? DateTime.now().millisecondsSinceEpoch;
    return ((end - startTime) / 60000).floor();
  }

  Map<String, dynamic> toJson() => {
        'startTime': startTime,
        'endTime': endTime,
        'blockedApps': blockedApps,
      };

  factory BlockingSession.fromJson(Map<String, dynamic> json) => BlockingSession(
        startTime: json['startTime'] as int,
        endTime: json['endTime'] as int?,
        blockedApps: List<String>.from(json['blockedApps'] as List),
      );

  static String encodeList(List<BlockingSession> sessions) {
    return jsonEncode(sessions.map((s) => s.toJson()).toList());
  }

  static List<BlockingSession> decodeList(String? jsonStr) {
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      final list = jsonDecode(jsonStr) as List;
      return list.map((e) => BlockingSession.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }
}

class BlockingStats {
  final int totalMinutes;
  final int weekMinutes;
  final int todayMinutes;
  final List<AppBlockStats> topBlockedApps;

  BlockingStats({
    required this.totalMinutes,
    required this.weekMinutes,
    required this.todayMinutes,
    required this.topBlockedApps,
  });
}

class AppBlockStats {
  final String packageName;
  final String appName;
  final int totalMinutes;

  AppBlockStats({
    required this.packageName,
    required this.appName,
    required this.totalMinutes,
  });
}
