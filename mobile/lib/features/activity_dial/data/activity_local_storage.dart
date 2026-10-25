import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/activity_log.dart';

final activityLocalStorageProvider = Provider<ActivityLocalStorage>((ref) {
  return ActivityLocalStorage();
});

/// Kho lưu trữ Local cho nhật ký cá nhân (DAT-01).
/// Đảm bảo hoạt động hoàn toàn offline, không mất dữ liệu khi tắt mở lại app (BR-02).
class ActivityLocalStorage {
  static const _keyLogs = 'cham_activity_logs_v1';
  static const _keyUser = 'cham_user_profile_v1';

  Future<List<ActivityLog>> loadLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyLogs);
    if (raw == null || raw.isEmpty) return [];

    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((item) => ActivityLog.fromJson(item as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    } catch (_) {
      return [];
    }
  }

  Future<void> saveLogs(List<ActivityLog> logs) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(logs.map((e) => e.toJson()).toList());
    await prefs.setString(_keyLogs, raw);
  }

  Future<void> appendLog(ActivityLog log) async {
    final current = await loadLogs();
    final updated = [log, ...current];
    await saveLogs(updated);
  }

  Future<void> deleteLog(String id) async {
    final current = await loadLogs();
    final updated = current.where((l) => l.id != id).toList();
    await saveLogs(updated);
  }

  Future<Map<String, String>?> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyUser);
    if (raw == null) return null;
    return Map<String, String>.from(jsonDecode(raw) as Map);
  }

  Future<void> saveProfile(String displayName, String inviteCode, String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _keyUser,
      jsonEncode({
        'displayName': displayName,
        'inviteCode': inviteCode,
        'token': token,
      }),
    );
  }
}
