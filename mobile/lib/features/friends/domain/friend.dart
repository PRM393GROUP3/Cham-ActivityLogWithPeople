/// Một người bạn đã kết nối qua QR (SOC-02).
class Friend {
  const Friend({required this.id, required this.displayName, required this.since, this.avatarEmoji});

  final String id;
  final String displayName;
  final String? avatarEmoji;
  final DateTime since;

  factory Friend.fromJson(Map<String, dynamic> json) => Friend(
        id: json['id'] as String,
        displayName: json['displayName'] as String,
        avatarEmoji: json['avatarEmoji'] as String?,
        since: DateTime.parse(json['since'] as String),
      );
}
