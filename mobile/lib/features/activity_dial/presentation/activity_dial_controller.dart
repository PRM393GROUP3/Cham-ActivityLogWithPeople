import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/activity_local_storage.dart';
import '../domain/activity_event_type.dart';
import '../domain/activity_log.dart';

class ActivityDialState {
  const ActivityDialState({
    required this.logs,
    required this.eventTypes,
    required this.isLoading,
    this.lastTappedType,
    this.displayName = 'Bạn',
    this.inviteCode = 'CHAM-8888',
  });

  final List<ActivityLog> logs;
  final List<ActivityEventType> eventTypes;
  final bool isLoading;
  final ActivityEventType? lastTappedType;
  final String displayName;
  final String inviteCode;

  /// Danh sách bản ghi trong ngày hôm nay (từ 00:00 đến 23:59)
  List<ActivityLog> get todayLogs {
    final now = DateTime.now();
    return logs.where((l) {
      return l.occurredAt.year == now.year &&
          l.occurredAt.month == now.month &&
          l.occurredAt.day == now.day;
    }).toList();
  }

  /// Số lượng chấm đã ghi trong hôm nay (khớp badge "🔴 4 chấm" trên banner)
  int get todayCount => todayLogs.length;

  /// Lần ghi gần nhất (HIS-01)
  ActivityLog? get latestLog => logs.isNotEmpty ? logs.first : null;

  ActivityDialState copyWith({
    List<ActivityLog>? logs,
    List<ActivityEventType>? eventTypes,
    bool? isLoading,
    ActivityEventType? lastTappedType,
    String? displayName,
    String? inviteCode,
  }) {
    return ActivityDialState(
      logs: logs ?? this.logs,
      eventTypes: eventTypes ?? this.eventTypes,
      isLoading: isLoading ?? this.isLoading,
      lastTappedType: lastTappedType ?? this.lastTappedType,
      displayName: displayName ?? this.displayName,
      inviteCode: inviteCode ?? this.inviteCode,
    );
  }
}

final activityDialControllerProvider =
    NotifierProvider<ActivityDialController, ActivityDialState>(
  ActivityDialController.new,
);

class ActivityDialController extends Notifier<ActivityDialState> {
  ActivityLocalStorage get _storage => ref.read(activityLocalStorageProvider);
  final _random = Random.secure();

  @override
  ActivityDialState build() {
    Future.microtask(_init);
    return const ActivityDialState(
      logs: [],
      eventTypes: ActivityEventType.defaultTypes,
      isLoading: true,
    );
  }

  Future<void> _init() async {
    final storedLogs = await _storage.loadLogs();

    // Nếu chưa có bản ghi nào, tạo sẵn 4 bản ghi mẫu hôm nay để khớp chính xác thiết kế "4 chấm"
    if (storedLogs.isEmpty) {
      final now = DateTime.now();
      final seedLogs = [
        ActivityLog(
          id: _generateUuid(),
          eventTypeId: 'coffee',
          name: 'Cà phê',
          emoji: '☕',
          occurredAt: now.subtract(const Duration(minutes: 45)),
        ),
        ActivityLog(
          id: _generateUuid(),
          eventTypeId: 'water',
          name: 'Nước',
          emoji: '💧',
          occurredAt: now.subtract(const Duration(hours: 2, minutes: 10)),
        ),
        ActivityLog(
          id: _generateUuid(),
          eventTypeId: 'focus',
          name: 'Tập trung',
          emoji: '💻',
          occurredAt: now.subtract(const Duration(hours: 3)),
        ),
        ActivityLog(
          id: _generateUuid(),
          eventTypeId: 'reading',
          name: 'Đọc sách',
          emoji: '📖',
          occurredAt: now.subtract(const Duration(hours: 4, minutes: 30)),
        ),
      ];
      await _storage.saveLogs(seedLogs);
      state = state.copyWith(
        logs: seedLogs,
        isLoading: false,
      );
      return;
    }

    state = state.copyWith(
      logs: storedLogs,
      isLoading: false,
    );
  }

  /// Ghi nhận 1-chạm tức thì với thời điểm hiện tại (LOG-03, BR-01, DAT-01).
  /// Không mở form, không hỏi thêm.
  Future<ActivityLog> quickLog(ActivityEventType type) async {
    final newLog = ActivityLog(
      id: _generateUuid(),
      eventTypeId: type.id,
      name: type.name,
      emoji: type.emoji,
      occurredAt: DateTime.now(),
      isSharedOnline: type.shareByDefault,
    );

    // Lưu vào Local Storage (BR-02)
    final updatedLogs = [newLog, ...state.logs];
    state = state.copyWith(
      logs: updatedLogs,
      lastTappedType: type,
    );

    await _storage.saveLogs(updatedLogs);
    return newLog;
  }

  /// Xóa bản ghi trong lịch sử (HIS-02, LOG-04: không Undo, chỉ Delete).
  Future<void> deleteLog(String id) async {
    final updatedLogs = state.logs.where((l) => l.id != id).toList();
    state = state.copyWith(logs: updatedLogs);
    await _storage.saveLogs(updatedLogs);
  }

  /// Sinh UUID ngẫu nhiên tuân thủ chuẩn RFC 4122 v4
  String _generateUuid() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
    bytes[8] = (bytes[8] & 0x3f) | 0x80; // variant
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}
