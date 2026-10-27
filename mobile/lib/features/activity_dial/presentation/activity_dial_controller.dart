import 'package:flutter/widgets.dart' show StringCharacters;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/time/vn_time.dart';
import '../../../core/utils/uuid.dart';
import '../../account/presentation/account_controller.dart';
import '../../sharing/data/share_api.dart';
import '../../sharing/data/share_outbox.dart';
import '../../sharing/domain/share_op.dart';
import '../../social/presentation/controllers/feed_controller.dart';
import '../../widgets/data/home_widget_bridge.dart';
import '../data/activity_local_storage.dart';
import '../data/event_type_storage.dart';
import '../domain/activity_event_type.dart';
import '../domain/activity_log.dart';
import '../domain/dial_layout.dart';

class ActivityDialState {
  const ActivityDialState({
    required this.logs,
    required this.eventTypes,
    required this.isLoading,
    this.lastTappedType,
  });

  final List<ActivityLog> logs;

  /// Mọi loại sự kiện theo thứ tự người dùng đặt trong Cài đặt (LOG-05).
  final List<ActivityEventType> eventTypes;
  final bool isLoading;
  final ActivityEventType? lastTappedType;

  /// Mọi loại sự kiện, đã được gán vòng và góc trên vòng Dial theo thứ tự.
  List<ActivityEventType> get dialTypes => layoutDial(eventTypes);

  /// Bản ghi trong ngày hôm nay theo giờ Việt Nam (HIS-01, DAT-02).
  List<ActivityLog> get todayLogs =>
      logs.where((l) => VnTime.isToday(l.occurredAt)).toList();

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
    HomeWidgetBridge.registerOnWidgetLogged(() {
      reloadFromExternal();
    });
    Future.microtask(_init);
    return const ActivityDialState(
      logs: [],
      eventTypes: ActivityEventType.defaultTypes,
      isLoading: true,
    );
  }

  /// Đọc lại danh sách bản ghi từ SharedPreferences khi người dùng vừa chấm từ Widget ngoài màn hình chính (WID-01).
  Future<void> reloadFromExternal() async {
    final storedLogs = await _storage.loadLogs(reloadPlatform: true);
    if (storedLogs.isNotEmpty) {
      state = state.copyWith(logs: storedLogs, isLoading: false);
    }
  }

  Future<void> _init() async {
    state = state.copyWith(
      eventTypes: await ref.read(eventTypeStorageProvider).load(),
    );

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
    await HomeWidgetBridge.updateWidgets();

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
    state = state.copyWith(logs: updatedLogs, lastTappedType: type);

    await _storage.saveLogs(updatedLogs);
    return newLog;
  }

  /// Tạo loại sự kiện mới ở cuối danh sách (LOG-01, LOG-02, LOG-05).
  /// Ném [ArgumentError] nếu thiếu emoji / tên hoặc tên quá 50 ký tự.
  Future<ActivityEventType> addEventType({
    required String emoji,
    required String name,
  }) async {
    final (e, n) = _validateType(emoji, name);
    if (state.eventTypes.length >= maxEventTypes) {
      throw ArgumentError('Tối đa $maxEventTypes loại sự kiện để vòng tròn còn dễ nhìn.');
    }
    final type = ActivityEventType.custom(id: 'custom-${uuidV4()}', name: n, emoji: e);
    await _saveTypes([...state.eventTypes, type]);
    return type;
  }

  /// Đổi emoji / tên một loại sự kiện. Chỉ áp dụng cho lần chạm sau: bản ghi cũ giữ emoji và
  /// tên lúc ghi.
  Future<void> updateEventType(String id, {required String emoji, required String name}) async {
    final (e, n) = _validateType(emoji, name);
    await _saveTypes([
      for (final t in state.eventTypes) t.id == id ? t.copyWith(emoji: e, name: n) : t,
    ]);
  }

  /// Xoá một loại sự kiện khỏi trang chủ. Bản ghi cũ của loại đó vẫn nằm trong lịch sử
  /// (và bản đã Công khai vẫn được chia sẻ). Không xoá được loại cuối cùng.
  Future<void> deleteEventType(String id) async {
    if (state.eventTypes.length <= 1) {
      throw ArgumentError('Cần giữ lại ít nhất một loại sự kiện.');
    }
    await _saveTypes(state.eventTypes.where((t) => t.id != id).toList());
  }

  /// Kéo thả đổi thứ tự: chuyển loại ở [oldIndex] tới vị trí [newIndex] trong danh sách sau khi
  /// đã bỏ nó ra (quy ước của `ReorderableListView.onReorderItem`).
  Future<void> reorderEventTypes(int oldIndex, int newIndex) async {
    final types = [...state.eventTypes];
    types.insert(newIndex, types.removeAt(oldIndex));
    await _saveTypes(types);
  }

  (String, String) _validateType(String emoji, String name) {
    final e = emoji.trim(), n = name.trim();
    if (e.isEmpty) throw ArgumentError('Hãy chọn một emoji.');
    if (n.isEmpty) throw ArgumentError('Hãy đặt tên cho sự kiện.');
    if (n.characters.length > 50) throw ArgumentError('Tên tối đa 50 ký tự.');
    return (e, n);
  }

  Future<void> _saveTypes(List<ActivityEventType> types) async {
    state = state.copyWith(eventTypes: types);
    await ref.read(eventTypeStorageProvider).save(types);
    await HomeWidgetBridge.updateWidgets();
  }

  /// Viết / sửa ghi chú của một bản ghi (NOTE-01). Chuỗi rỗng = xoá ghi chú.
  /// Chỉ lưu trên máy; không đụng tới hàng đợi chia sẻ.
  Future<void> setNote(String id, String note) async {
    final log = _find(id);
    if (log == null) return;
    final value = note.trim().isEmpty ? null : note.trimRight();
    if (value == log.note) return;
    await _updateLog(log.copyWith(note: () => value));
  }

  /// Đổi chế độ chia sẻ của một bản ghi (SOC-03, SOC-04). Lưu local trước, sau đó đưa vào
  /// hàng đợi gửi; mất mạng thì bản ghi ở trạng thái chờ và được gửi lại sau (DAT-03).
  Future<void> setVisibility(String id, ShareVisibility visibility) async {
    final log = _find(id);
    if (log == null || log.visibility == visibility) return;

    await _outbox.put(
      visibility == ShareVisibility.public
          ? ShareOp.publish(
              recordId: log.id,
              emoji: log.emoji,
              name: log.name,
              occurredAt: log.occurredAt,
            )
          : ShareOp.revoke(log.id),
    );
    await _updateLog(
      log.copyWith(visibility: visibility, syncStatus: ShareSyncStatus.pending),
    );
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
    var sent = false;
    for (final op in ops) {
      try {
        await api.send(op);
        sent = true;
        await _outbox.complete(op);
        if (!await _outbox.contains(op.recordId)) {
          await _markSynced(op.recordId);
        }
      } on ApiException catch (e) {
        await _markFailed([op.recordId]);
        // Mất mạng: các thao tác sau cũng sẽ lỗi, để lần sau.
        if (e.isNetworkError) break;
      }
    }
    // Bài của mình trong feed (và cảm xúc trên đó) đổi theo: tải lại feed nếu đang mở.
    if (sent) ref.invalidate(feedControllerProvider);
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
    if (log != null) {
      await _updateLog(log.copyWith(syncStatus: ShareSyncStatus.synced));
    }
  }

  Future<void> _markFailed(Iterable<String> ids) async {
    for (final id in ids) {
      final log = _find(id);
      if (log != null) {
        await _updateLog(log.copyWith(syncStatus: ShareSyncStatus.failed));
      }
    }
  }
}
