import 'dart:typed_data';

class AppInfo {
  final String packageName;
  final String appName;
  final Uint8List? icon;
  bool isBlocked;

  AppInfo({
    required this.packageName,
    required this.appName,
    this.icon,
    this.isBlocked = false,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppInfo &&
          runtimeType == other.runtimeType &&
          packageName == other.packageName;

  @override
  int get hashCode => packageName.hashCode;
}
