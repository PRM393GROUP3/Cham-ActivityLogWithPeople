import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../account/presentation/account_controller.dart';
import '../../data/feed_api.dart';
import '../../domain/feed_share.dart';

/// Feed: bản ghi Công khai của bạn bè (SOC-05) lẫn của chính mình — để xem bạn bè đã thả cảm xúc
/// gì — mới nhất trước. Tự tạo tài khoản ẩn danh ở lần đầu (cần mạng).
final feedControllerProvider = AsyncNotifierProvider<FeedController, List<FeedShare>>(FeedController.new);

class FeedController extends AsyncNotifier<List<FeedShare>> {
  FeedApi get _api => ref.read(feedApiProvider);

  @override
  Future<List<FeedShare>> build() async {
    final me = await ref.read(accountControllerProvider.notifier).ensure();
    final (friends, own) = await (_api.fetch(), _api.fetchOwn()).wait;
    return [
      ...friends,
      for (final json in own)
        FeedShare.fromOwnJson(json, ownerId: me.id, ownerName: me.displayName, ownerAvatarEmoji: me.avatarEmoji),
    ]..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(build);
  }

  /// Chạm emoji: thả, đổi sang emoji khác, hoặc gỡ nếu chạm lại emoji đang chọn (AC-07).
  /// Cập nhật giao diện ngay, hoàn tác nếu server từ chối.
  Future<void> toggleReaction(String shareId, String emoji) async {
    final current = state.value;
    final share = current?.where((s) => s.id == shareId).firstOrNull;
    if (current == null || share == null || share.isMine) return;

    final next = share.myReaction == emoji ? null : emoji;
    _replace(share.withMyReaction(next));
    try {
      if (next == null) {
        await _api.unreact(shareId);
      } else {
        _replace(await _api.react(shareId, next));
      }
    } catch (_) {
      _replace(share);
      rethrow;
    }
  }

  void _replace(FeedShare updated) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData([for (final s in current) s.id == updated.id ? updated : s]);
  }
}
