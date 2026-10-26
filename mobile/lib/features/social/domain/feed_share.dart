/// Một bản ghi Public của bạn bè trong feed (SOC-05).
class FeedShare {
  const FeedShare({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    required this.emoji,
    required this.name,
    required this.occurredAt,
    this.reactionCounts = const {},
    this.myReaction,
  });

  final String id;
  final String ownerId;
  final String ownerName;
  final String emoji;
  final String name;
  final DateTime occurredAt;

  /// Số người đã thả từng emoji.
  final Map<String, int> reactionCounts;

  /// Reaction của chính mình (mỗi người tối đa 1), hoặc `null`.
  final String? myReaction;

  int get totalReactions => reactionCounts.values.fold(0, (a, b) => a + b);

  factory FeedShare.fromJson(Map<String, dynamic> json) {
    final owner = json['owner'] as Map<String, dynamic>;
    return FeedShare(
      id: json['id'] as String,
      ownerId: owner['id'] as String,
      ownerName: owner['displayName'] as String,
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
      emoji: this.emoji,
      name: name,
      occurredAt: occurredAt,
      reactionCounts: counts,
      myReaction: emoji,
    );
  }
}
