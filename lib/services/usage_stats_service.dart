import 'package:flutter/services.dart';

class AppUsageEntry {
  const AppUsageEntry({required this.packageName, required this.appName, required this.foregroundMillis});
  final String packageName;
  final String appName;
  final int foregroundMillis;

  Duration get duration => Duration(milliseconds: foregroundMillis);

  factory AppUsageEntry.fromMap(Map<Object?, Object?> map) => AppUsageEntry(
    packageName: map['packageName'] as String? ?? '',
    appName: map['appName'] as String? ?? (map['packageName'] as String? ?? 'Unknown app'),
    foregroundMillis: (map['foregroundMillis'] as num?)?.toInt() ?? 0,
  );
}

class UsageStatsService {
  UsageStatsService._();
  static const _channel = MethodChannel('app.lifeos/usage_stats');

  static Future<bool> hasUsageAccess() async =>
      await _channel.invokeMethod<bool>('hasUsageAccess') ?? false;

  static Future<void> openUsageAccessSettings() =>
      _channel.invokeMethod<void>('openUsageAccessSettings');

  static Future<List<AppUsageEntry>> getTodayUsage() async {
    final raw = await _channel.invokeMethod<List<Object?>>('getTodayUsage') ?? [];
    return raw
      .whereType<Map<Object?, Object?>>()
      .map(AppUsageEntry.fromMap)
      .where((entry) => entry.foregroundMillis > 0)
      .toList(growable: false);
  }
}
