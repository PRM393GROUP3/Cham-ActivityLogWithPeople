import 'package:cham/features/activity_dial/domain/activity_event_type.dart';
import 'package:cham/features/activity_dial/domain/activity_log.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ActivityEventType & ActivityLog Tests', () {
    test('contains 19 standard event types on 3 orbits', () {
      final types = ActivityEventType.defaultTypes;
      expect(types.length, 19);

      final orbit1 = types.where((t) => t.orbit == 1).toList();
      final orbit2 = types.where((t) => t.orbit == 2).toList();
      final orbit3 = types.where((t) => t.orbit == 3).toList();

      expect(orbit1.length, 6);
      expect(orbit2.length, 6);
      expect(orbit3.length, 7);

      expect(orbit1.map((t) => t.name), containsAll(['Cà phê', 'Nước', 'Chạy bộ', 'Ăn uống', 'Tập trung', 'Đọc sách']));
      expect(orbit2.map((t) => t.name), containsAll(['Thiền', 'Đi dạo', 'Ngủ', 'Dọn dẹp', 'Nghe nhạc', 'Thú cưng']));
      expect(orbit3.map((t) => t.name), containsAll(['Nấu ăn', 'Tưới cây', 'Gym', 'Xem phim', 'Nhật ký', 'Mua sắm', 'Đạp xe']));
    });

    test('serializes and deserializes ActivityLog to/from JSON correctly', () {
      final log = ActivityLog(
        id: '0b7f5c1e-3f0a-4c55-9d0e-2b8f1a6c7d90',
        eventTypeId: 'coffee',
        name: 'Cà phê',
        emoji: '☕',
        occurredAt: DateTime.utc(2026, 10, 1, 1, 30),
        visibility: ShareVisibility.public,
        syncStatus: ShareSyncStatus.pending,
      );

      final restored = ActivityLog.fromJson(log.toJson());

      expect(restored.id, log.id);
      expect(restored.eventTypeId, log.eventTypeId);
      expect(restored.name, log.name);
      expect(restored.emoji, log.emoji);
      expect(restored.occurredAt, log.occurredAt);
      expect(restored.visibility, ShareVisibility.public);
      expect(restored.syncStatus, ShareSyncStatus.pending);
    });

    test('new records and records saved by older versions are Private (SOC-03)', () {
      final legacy = ActivityLog.fromJson({
        'id': 'a',
        'eventTypeId': 'coffee',
        'name': 'Cà phê',
        'emoji': '☕',
        'occurredAt': '2026-10-01T08:00:00.000',
        'isSharedOnline': true,
      });
      expect(legacy.visibility, ShareVisibility.private);
      expect(legacy.syncStatus, ShareSyncStatus.synced);
    });
  });
}
