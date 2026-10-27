import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../widgets/data/home_widget_bridge.dart';
import '../domain/activity_log.dart';

final activityLocalStorageProvider = Provider<ActivityLocalStorage>((ref) {
  return ActivityLocalStorage();
});

/// Kho lưu trữ Local cho nhật ký cá nhân (DAT-01).
/// Đảm bảo hoạt động hoàn toàn offline, không mất dữ liệu khi tắt mở lại app (BR-02).
class ActivityLocalStorage {
  static const _keyLogs = 'cham_activity_logs_v1';

  static final _legacyHexId = RegExp(r'^[0-9a-f]{32}$');

  Future<List<ActivityLog>> loadLogs({bool reloadPlatform = false}) async {
    final prefs = await SharedPreferences.getInstance();
    if (reloadPlatform && HomeWidgetBridge.isRealAndroidApp) {
      try {
        await prefs.reload();
      } catch (_) {}
    }
    final raw = prefs.getString(_keyLogs);
    if (raw == null || raw.isEmpty) return [];

    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((item) => ActivityLog.fromJson(_upgrade(item as Map<String, dynamic>))).toList()
        ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    } catch (_) {
      return [];
    }
  }

  Future<void> saveLogs(List<ActivityLog> logs) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(logs.map((e) => e.toJson()).toList());
    await prefs.setString(_keyLogs, raw);
    await HomeWidgetBridge.updateWidgets();
  }

  /// Bản cũ sinh id 32 ký tự hex không có dấu gạch; server chỉ nhận UUID chuẩn.
  /// Chèn dấu gạch giữ nguyên danh tính bản ghi (chưa bản nào từng được gửi lên server).
  Map<String, dynamic> _upgrade(Map<String, dynamic> json) {
    final id = json['id'] as String;
    if (!_legacyHexId.hasMatch(id)) return json;
    return {
      ...json,
      'id': '${id.substring(0, 8)}-${id.substring(8, 12)}-${id.substring(12, 16)}-'
          '${id.substring(16, 20)}-${id.substring(20)}',
    };
  }
}
