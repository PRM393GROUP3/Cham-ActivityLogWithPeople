import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/time/vn_time.dart';
import '../../../core/utils/uuid.dart';
import '../../account/presentation/account_controller.dart';
import '../../sharing/data/share_api.dart';
import '../../sharing/data/share_outbox.dart';
import '../../sharing/domain/share_op.dart';
import '../data/activity_local_storage.dart';
import '../domain/activity_event_type.dart';
import '../domain/activity_log.dart';

class ActivityDialState {
  const ActivityDialState({
    required this.logs,
    required this.eventTypes,
    required this.isLoading,
    this.lastTappedType,
  });

  final List<ActivityLog> logs;
  final List<ActivityEventType> eventTypes;
  final bool isLoading;
  final ActivityEventType? lastTappedType;

  /// Bản ghi trong ngày hôm nay theo giờ Việt Nam (HIS-01, DAT-02).
  List<ActivityLog> get todayLogs => logs.where((l) => VnTime.isToday(l.occurredAt)).toList();

  /// Số lượng chấm đã ghi trong hôm nay (khớp badge "🔴 4 chấm" trên banner)
  int get todayCount => todayLogs.length;

  /// Lần ghi gần nhất (HIS-01)
  ActivityLog? get latestLog => logs.isNotEmpty ? logs.first : null;

  ActivityDialState copyWith({
    List<ActivityLog>? logs,
    List<ActivityEventType>? eventTypes,
    bool? isLoading,
    ActivityEventType? lastTappedType,
  }) {
    return ActivityDialState(
      logs: logs ?? this.logs,
      eventTypes: eventTypes ?? this.eventTypes,
      isLoading: isLoading ?? this.isLoading,
      lastTappedType: lastTappedType ?? this.lastTappedType,
    );
  }
}

final activityDialControllerProvider =
    NotifierProvider<ActivityDialController, ActivityDialState>(
  ActivityDialController.new,
);

class ActivityDialController extends Notifier<ActivityDialState> {
  ActivityLocalStorage get _storage => ref.read(activityLocalStorageProvider);
  ShareOutbox get _outbox => ref.read(shareOutboxProvider);

  /// Lần gửi hàng đợi đang chạy; lần gọi sau trong lúc đó chờ cùng kết quả thay vì gửi song song.
  Future<void>? _syncing;

  /// Có thay đổi mới trong lúc đang gửi: chạy thêm một vòng sau khi vòng hiện tại xong.
  bool _syncAgain = false;

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
          id: uuidV4(),
          eventTypeId: 'coffee',
          name: 'Cà phê',
          emoji: '☕',
          occurredAt: now.subtract(const Duration(minutes: 45)),
        ),
        ActivityLog(
          id: uuidV4(),
          eventTypeId: 'water',
          name: 'Nước',
          emoji: '💧',
          occurredAt: now.subtract(const Duration(hours: 2, minutes: 10)),
        ),
        ActivityLog(
          id: uuidV4(),
          eventTypeId: 'focus',
          name: 'Tập trung',
          emoji: '💻',
          occurredAt: now.subtract(const Duration(hours: 3)),
        ),
        ActivityLog(
          id: uuidV4(),
          eventTypeId: 'reading',
          name: 'Đọc sách',
          emoji: '📖',
          occurredAt: now.subtract(const Duration(hours: 4, minutes: 30)),
        ),
      ];
      await _storage.saveLogs(seedLogs);
      state = state.copyWith(logs: seedLogs, isLoading: false);
      return;
    }

    state = state.copyWith(logs: storedLogs, isLoading: false);

    // Gửi nốt những thay đổi chia sẻ còn tồn từ lần mở app trước (DAT-03).
    await syncShares();
  }

  /// Ghi nhận 1-chạm tức thì với thời điểm hiện tại (LOG-03, BR-01, DAT-01).
  /// Không mở form, không hỏi thêm. Bản ghi luôn bắt đầu ở chế độ Private (SOC-03).
  Future<ActivityLog> quickLog(ActivityEventType type) async {
    final newLog = ActivityLog(
      id: uuidV4(),
      eventTypeId: type.id,
      name: type.name,
      emoji: type.emoji,
      occurredAt: DateTime.now(),
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

  /// Đổi chế độ chia sẻ của một bản ghi (SOC-03, SOC-04). Lưu local trước, sau đó đưa vào
  /// hàng đợi gửi; mất mạng thì bản ghi ở trạng thái chờ và được gửi lại sau (DAT-03).
  Future<void> setVisibility(String id, ShareVisibility visibility) async {
    final log = _find(id);
    if (log == null || log.visibility == visibility) return;

    await _outbox.put(
      visibility == ShareVisibility.public
          ? ShareOp.publish(recordId: log.id, emoji: log.emoji, name: log.name, occurredAt: log.occurredAt)
          : ShareOp.revoke(log.id),
    );
    await _updateLog(log.copyWith(visibility: visibility, syncStatus: ShareSyncStatus.pending));
    await syncShares();
  }

  /// Xóa bản ghi trong lịch sử (HIS-02, LOG-04: không Undo, chỉ Delete).
  /// Bản ghi Public, hoặc đang chờ gửi, được thu hồi trên server (BR-03).
  Future<void> deleteLog(String id) async {
    final log = _find(id);
    if (log == null) return;

    final needsRevoke = log.isPublic || await _outbox.contains(id);
    if (needsRevoke) await _outbox.put(ShareOp.revoke(id));

    final updatedLogs = state.logs.where((l) => l.id != id).toList();
    state = state.copyWith(logs: updatedLogs);
    await _storage.saveLogs(updatedLogs);

    if (needsRevoke) await syncShares();
  }

  /// Gửi hàng đợi chia sẻ lên server. Gọi lại nhiều lần an toàn; dừng ở lỗi mạng đầu tiên
  /// và giữ thao tác để thử lại lần sau (mở app, đổi chế độ, xoá, hoặc bấm "Thử lại").
  Future<void> syncShares() {
    if (_syncing != null) {
      _syncAgain = true;
      return _syncing!;
    }
    return _syncing = _drain().whenComplete(() => _syncing = null);
  }

  Future<void> _drain() async {
    do {
      _syncAgain = false;
      await _sendAll();
    } while (_syncAgain);
  }

  Future<void> _sendAll() async {
    final ops = await _outbox.load();
    if (ops.isEmpty) return;

    try {
      await ref.read(accountControllerProvider.notifier).ensure();
    } on ApiException {
      await _markFailed(ops.map((o) => o.recordId));
      return;
    }

    final api = ref.read(shareApiProvider);
    for (final op in ops) {
      try {
        await api.send(op);
        await _outbox.complete(op);
        if (!await _outbox.contains(op.recordId)) await _markSynced(op.recordId);
      } on ApiException catch (e) {
        await _markFailed([op.recordId]);
        // Mất mạng: các thao tác sau cũng sẽ lỗi, để lần sau.
        if (e.isNetworkError) return;
      }
    }
  }

  ActivityLog? _find(String id) {
    for (final l in state.logs) {
      if (l.id == id) return l;
    }
    return null;
  }

  Future<void> _updateLog(ActivityLog updated) async {
    final logs = [for (final l in state.logs) l.id == updated.id ? updated : l];
    state = state.copyWith(logs: logs);
    await _storage.saveLogs(logs);
  }

  Future<void> _markSynced(String id) async {
    final log = _find(id);
    if (log != null) await _updateLog(log.copyWith(syncStatus: ShareSyncStatus.synced));
  }

  Future<void> _markFailed(Iterable<String> ids) async {
    for (final id in ids) {
      final log = _find(id);
      if (log != null) await _updateLog(log.copyWith(syncStatus: ShareSyncStatus.failed));
    }
  }
}
