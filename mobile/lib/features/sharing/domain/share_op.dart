/// Thao tác chia sẻ cần đồng bộ lên server cho một bản ghi.
enum ShareOpType {
  /// Bản ghi chuyển sang Public: PUT /api/shares/:id.
  publish,

  /// Bản ghi về Private hoặc bị xoá: DELETE /api/shares/:id (thu hồi, SOC-04).
  revoke,
}

/// Một mục trong hàng đợi gửi (DAT-03). Mỗi bản ghi chỉ giữ thao tác mới nhất: ý định cuối cùng
/// của người dùng là thứ duy nhất cần đồng bộ, và cả PUT lẫn DELETE đều idempotent.
class ShareOp {
  const ShareOp.publish({
    required this.recordId,
    required String this.emoji,
    required String this.name,
    required DateTime this.occurredAt,
  }) : type = ShareOpType.publish;

  const ShareOp.revoke(this.recordId)
      : type = ShareOpType.revoke,
        emoji = null,
        name = null,
        occurredAt = null;

  final String recordId;
  final ShareOpType type;
  final String? emoji;
  final String? name;

  /// Thời điểm ghi gốc, giữ nguyên khi gửi muộn (BR-02).
  final DateTime? occurredAt;

  Map<String, dynamic> toJson() => {
        'recordId': recordId,
        'type': type.name,
        if (emoji != null) 'emoji': emoji,
        if (name != null) 'name': name,
        if (occurredAt != null) 'occurredAt': occurredAt!.toUtc().toIso8601String(),
      };

  factory ShareOp.fromJson(Map<String, dynamic> json) => switch (ShareOpType.values.byName(json['type'] as String)) {
        ShareOpType.publish => ShareOp.publish(
            recordId: json['recordId'] as String,
            emoji: json['emoji'] as String,
            name: json['name'] as String,
            occurredAt: DateTime.parse(json['occurredAt'] as String),
          ),
        ShareOpType.revoke => ShareOp.revoke(json['recordId'] as String),
      };

  @override
  bool operator ==(Object other) =>
      other is ShareOp &&
      other.recordId == recordId &&
      other.type == type &&
      other.emoji == emoji &&
      other.name == name &&
      // So theo thời điểm thực: bản vừa tạo (giờ local) và bản đọc lại từ storage (UTC) là một.
      other.occurredAt?.microsecondsSinceEpoch == occurredAt?.microsecondsSinceEpoch;

  @override
  int get hashCode => Object.hash(recordId, type, emoji, name, occurredAt?.microsecondsSinceEpoch);
}
