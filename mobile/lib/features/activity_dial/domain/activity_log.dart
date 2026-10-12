/// Đại diện cho một bản ghi hoạt động cá nhân (LOG-03, BR-01).
/// Được lưu trữ offline tại local trước tiên (DAT-01).
class ActivityLog {
  const ActivityLog({
    required this.id,
    required this.eventTypeId,
    required this.name,
    required this.emoji,
    required this.occurredAt,
    this.isSharedOnline = false,
  });

  /// ID cục bộ dạng UUID v4 (dùng để upsert idempotent lên server: PUT /api/shares/:id)
  final String id;
  final String eventTypeId;
  final String name;
  final String emoji;
  final DateTime occurredAt;
  final bool isSharedOnline;

  ActivityLog copyWith({
    String? id,
    String? eventTypeId,
    String? name,
    String? emoji,
    DateTime? occurredAt,
    bool? isSharedOnline,
  }) {
    return ActivityLog(
      id: id ?? this.id,
      eventTypeId: eventTypeId ?? this.eventTypeId,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      occurredAt: occurredAt ?? this.occurredAt,
      isSharedOnline: isSharedOnline ?? this.isSharedOnline,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'eventTypeId': eventTypeId,
        'name': name,
        'emoji': emoji,
        'occurredAt': occurredAt.toIso8601String(),
        'isSharedOnline': isSharedOnline,
      };

  factory ActivityLog.fromJson(Map<String, dynamic> json) => ActivityLog(
        id: json['id'] as String,
        eventTypeId: json['eventTypeId'] as String,
        name: json['name'] as String,
        emoji: json['emoji'] as String,
        occurredAt: DateTime.parse(json['occurredAt'] as String),
        isSharedOnline: (json['isSharedOnline'] as bool?) ?? false,
      );
}
