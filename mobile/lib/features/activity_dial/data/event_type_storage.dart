import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/activity_event_type.dart';

final eventTypeStorageProvider = Provider<EventTypeStorage>(
  (ref) => EventTypeStorage(),
);

/// Loại sự kiện người dùng tự tạo, lưu trên máy theo thứ tự tạo (LOG-05, NFR-01).
class EventTypeStorage {
  static const _key = 'cham_custom_event_types_v1';

  Future<List<ActivityEventType>> load() async {
    final raw = (await SharedPreferences.getInstance()).getString(_key);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) => ActivityEventType.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> save(List<ActivityEventType> types) async {
    await (await SharedPreferences.getInstance()).setString(
      _key,
      jsonEncode(types.map((t) => t.toJson()).toList()),
    );
  }
}
