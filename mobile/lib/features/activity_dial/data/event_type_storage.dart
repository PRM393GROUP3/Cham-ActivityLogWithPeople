import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/activity_event_type.dart';

final eventTypeStorageProvider = Provider<EventTypeStorage>((ref) => EventTypeStorage());

/// Danh sách loại sự kiện theo thứ tự người dùng đặt, lưu trên máy (LOG-05, NFR-01).
/// Chưa từng chỉnh sửa → dùng 19 loại mặc định.
class EventTypeStorage {
  static const _key = 'cham_event_types_v2';

  /// Bản trước chỉ lưu các loại tự tạo (thêm sau 19 loại mặc định).
  static const _legacyCustomKey = 'cham_custom_event_types_v1';

  Future<List<ActivityEventType>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      try {
        return _decode(raw);
      } catch (_) {
        return ActivityEventType.defaultTypes;
      }
    }
    final legacy = prefs.getString(_legacyCustomKey);
    if (legacy != null) {
      try {
        return [...ActivityEventType.defaultTypes, ..._decode(legacy)];
      } catch (_) {}
    }
    return ActivityEventType.defaultTypes;
  }

  Future<void> save(List<ActivityEventType> types) async {
    await (await SharedPreferences.getInstance())
        .setString(_key, jsonEncode(types.map((t) => t.toJson()).toList()));
  }

  List<ActivityEventType> _decode(String raw) =>
      (jsonDecode(raw) as List).map((e) => ActivityEventType.fromJson(e as Map<String, dynamic>)).toList();
}
