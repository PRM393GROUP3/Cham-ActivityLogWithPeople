import 'dart:convert';

/// Gợi ý "có gì đó đã đổi, hãy tải lại" do server đẩy qua WebSocket. Không chứa dữ liệu: app tải
/// lại qua REST API (nơi kiểm tra quyền), khớp `RealtimeEvent` ở `backend/src/infrastructure/realtime`.
sealed class RealtimeEvent {
  const RealtimeEvent();

  /// `null` với tin không hiểu được (vd. `pong`, hay loại sự kiện mới hơn bản app này).
  static RealtimeEvent? tryParse(Object? message) {
    if (message is! String || !message.startsWith('{')) return null;
    try {
      final json = jsonDecode(message) as Map<String, dynamic>;
      return switch (json['type']) {
        'share.upserted' => ShareUpserted(json['id'] as String),
        'share.removed' => ShareRemoved(json['id'] as String),
        'reaction.changed' => ReactionChanged(json['shareId'] as String),
        'friends.changed' => const FriendsChanged(),
        _ => null,
      };
    } catch (_) {
      return null;
    }
  }
}

/// Một bản ghi Công khai của bạn bè vừa hiện ra hoặc vừa đổi.
class ShareUpserted extends RealtimeEvent {
  const ShareUpserted(this.id);
  final String id;
}

/// Một bản ghi bị xoá, hoặc mình không còn quyền xem.
class ShareRemoved extends RealtimeEvent {
  const ShareRemoved(this.id);
  final String id;
}

/// Có người vừa thả / đổi / gỡ cảm xúc trên bài của mình.
class ReactionChanged extends RealtimeEvent {
  const ReactionChanged(this.shareId);
  final String shareId;
}

/// Danh sách bạn bè vừa đổi (kết bạn / huỷ kết bạn).
class FriendsChanged extends RealtimeEvent {
  const FriendsChanged();
}
