/// Một người đã thả cảm xúc vào bài của mình.
class Reactor {
  const Reactor({required this.userId, required this.displayName, this.avatarEmoji, required this.emoji, required this.reactedAt});

  final String userId;
  final String displayName;
  final String? avatarEmoji;

  /// Cảm xúc đã thả.
  final String emoji;
  final DateTime reactedAt;

  factory Reactor.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>;
    return Reactor(
      userId: user['id'] as String,
      displayName: user['displayName'] as String,
      avatarEmoji: user['avatarEmoji'] as String?,
      emoji: json['emoji'] as String,
      reactedAt: DateTime.parse(json['reactedAt'] as String),
    );
  }
}

/// Một bản ghi Công khai trong feed: của bạn bè (SOC-05), hoặc của chính mình ([isMine]) để xem
/// bạn bè đã thả cảm xúc gì.
class FeedShare {
  const FeedShare({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    this.ownerAvatarEmoji,
    required this.emoji,
    required this.name,
    required this.occurredAt,
    this.reactionCounts = const {},
    this.myReaction,
    this.isMine = false,
    this.reactors = const [],
  });

  final String id;
  final String ownerId;
  final String ownerName;
  final String? ownerAvatarEmoji;
  final String emoji;
  final String name;
  final DateTime occurredAt;

  /// Số người đã thả từng emoji.
  final Map<String, int> reactionCounts;

  /// Reaction của chính mình (mỗi người tối đa 1), hoặc `null`. Luôn `null` với bài của mình.
  final String? myReaction;

  /// Bài của chính mình: không tự thả cảm xúc được, nhưng xem được [reactors].
  final bool isMine;

  /// Ai đã thả cảm xúc gì (chỉ có với bài của mình), mới nhất trước.
  final List<Reactor> reactors;

  int get totalReactions => reactionCounts.values.fold(0, (a, b) => a + b);

  factory FeedShare.fromJson(Map<String, dynamic> json) {
    final owner = json['owner'] as Map<String, dynamic>;
    return FeedShare(
      id: json['id'] as String,
      ownerId: owner['id'] as String,
      ownerName: owner['displayName'] as String,
      ownerAvatarEmoji: owner['avatarEmoji'] as String?,
      emoji: json['emoji'] as String,
      name: json['name'] as String,
      occurredAt: DateTime.parse(json['occurredAt'] as String),
      reactionCounts: {
        for (final r in (json['reactions'] as List).cast<Map<String, dynamic>>())
          r['emoji'] as String: (r['count'] as num).toInt(),
      },
      myReaction: json['myReaction'] as String?,
    );
  }

  /// Bài Công khai của chính mình từ `GET /api/shares` (kèm danh sách người thả cảm xúc).
  factory FeedShare.fromOwnJson(Map<String, dynamic> json, {required String ownerId, required String ownerName, String? ownerAvatarEmoji}) {
    final reactors = (json['reactions'] as List).map((e) => Reactor.fromJson(e as Map<String, dynamic>)).toList();
    final counts = <String, int>{};
    for (final r in reactors) {
      counts[r.emoji] = (counts[r.emoji] ?? 0) + 1;
    }
    return FeedShare(
      id: json['id'] as String,
      ownerId: ownerId,
      ownerName: ownerName,
      ownerAvatarEmoji: ownerAvatarEmoji,
      emoji: json['emoji'] as String,
      name: json['name'] as String,
      occurredAt: DateTime.parse(json['occurredAt'] as String),
      reactionCounts: counts,
      isMine: true,
      reactors: reactors,
    );
  }

  /// Đổi reaction của mình sang [emoji] (hoặc gỡ khi `null`), cập nhật lại số đếm.
  FeedShare withMyReaction(String? emoji) {
    final counts = Map<String, int>.of(reactionCounts);
    void bump(String e, int delta) {
      final next = (counts[e] ?? 0) + delta;
      if (next > 0) {
        counts[e] = next;
      } else {
        counts.remove(e);
      }
    }

    if (myReaction != null) bump(myReaction!, -1);
    if (emoji != null) bump(emoji, 1);
    return FeedShare(
      id: id,
      ownerId: ownerId,
      ownerName: ownerName,
      ownerAvatarEmoji: ownerAvatarEmoji,
      emoji: this.emoji,
      name: name,
      occurredAt: occurredAt,
      reactionCounts: counts,
      myReaction: emoji,
    );
  }
}
