import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../activity_dial/domain/activity_event_type.dart';
import '../domain/widget_config.dart';

/// Cầu nối đồng bộ cấu hình & dữ liệu giữa Flutter và Native Android AppWidgetProvider (WID-01, AC-01).
/// Tự động bỏ qua an toàn khi chạy trên Web hoặc trong môi trường unit/widget test.
class HomeWidgetBridge {
  static const _channel = MethodChannel('com.cham.cham/widgets');
  static const _keySmallType = 'cham_widget_small_type_v1';
  static const _keyMediumTypes = 'cham_widget_medium_types_v1';

  static VoidCallback? _onWidgetLogged;
  static bool _listenerRegistered = false;

  static bool get isRealAndroidApp {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return false;
    try {
      final bindingType = WidgetsBinding.instance.runtimeType.toString();
      return !bindingType.contains('Test');
    } catch (_) {
      return false;
    }
  }

  /// Đăng ký callback khi người dùng chạm nút ghi nhanh trên Widget ngoài màn hình chính Android.
  static void registerOnWidgetLogged(VoidCallback callback) {
    _onWidgetLogged = callback;
    if (_listenerRegistered || !isRealAndroidApp) return;
    _listenerRegistered = true;
    try {
      _channel.setMethodCallHandler((call) async {
        if (call.method == 'onWidgetLogged') {
          _onWidgetLogged?.call();
        }
      });
    } catch (_) {}
  }

  /// Làm mới toàn bộ Widget 2×2 và 4×2 ngoài màn hình chính Android.
  static Future<void> updateWidgets() async {
    if (!isRealAndroidApp) return;
    try {
      await _channel.invokeMethod<bool>('updateWidgets');
    } catch (_) {}
  }

  /// Yêu cầu Android Launcher ghim trực tiếp Widget (2×2 hoặc 4×2) ra màn hình chính (Android 8.0+).
  static Future<bool> pinWidget(WidgetSize size) async {
    if (!isRealAndroidApp) return false;
    try {
      final result = await _channel.invokeMethod<bool>(
        'pinWidget',
        {'size': size == WidgetSize.medium ? 'medium' : 'small'},
      );
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Đọc loại sự kiện đang gán cho Widget Nhỏ (2×2).
  static Future<ActivityEventType> loadSmallType(
    List<ActivityEventType> available,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_keySmallType);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        return ActivityEventType.fromJson(decoded);
      }
    } catch (_) {}
    return available.isNotEmpty
        ? available.first
        : ActivityEventType.defaultTypes.first;
  }

  /// Lưu loại sự kiện cho Widget Nhỏ (2×2) và cập nhật Native Widget.
  static Future<void> saveSmallType(ActivityEventType type) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keySmallType, jsonEncode(type.toJson()));
      await updateWidgets();
    } catch (_) {}
  }

  /// Đọc 4 loại sự kiện đang gán cho Widget Vừa (4×2).
  static Future<List<ActivityEventType>> loadMediumTypes(
    List<ActivityEventType> available,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_keyMediumTypes);
      if (raw != null && raw.isNotEmpty) {
        final list = (jsonDecode(raw) as List<dynamic>)
            .map((e) => ActivityEventType.fromJson(e as Map<String, dynamic>))
            .toList();
        if (list.length >= 4) return list.take(4).toList();
      }
    } catch (_) {}

    const defaultIds = ['coffee', 'running', 'reading', 'meditate'];
    final defaults = <ActivityEventType>[];
    for (final id in defaultIds) {
      final match = available.where((t) => t.id == id).firstOrNull ??
          ActivityEventType.defaultTypes.where((t) => t.id == id).firstOrNull;
      if (match != null) defaults.add(match);
    }
    for (final t in available) {
      if (defaults.length >= 4) break;
      if (!defaults.any((d) => d.id == t.id)) defaults.add(t);
    }
    return defaults.take(4).toList();
  }

  /// Lưu 4 loại sự kiện cho Widget Vừa (4×2) và cập nhật Native Widget.
  static Future<void> saveMediumTypes(List<ActivityEventType> types) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _keyMediumTypes,
        jsonEncode(types.take(4).map((t) => t.toJson()).toList()),
      );
      await updateWidgets();
    } catch (_) {}
  }
}
