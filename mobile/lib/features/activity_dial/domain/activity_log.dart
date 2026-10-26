/// Chế độ chia sẻ của một bản ghi (SOC-03).
enum ShareVisibility {
  /// Mặc định: chỉ lưu trên máy, không gửi lên server.
  private,

  /// Tất cả bạn bè xem được.
  public,
}

/// Trạng thái đồng bộ chế độ chia sẻ với server (NFR-03: tách khỏi trạng thái "đã lưu local").
enum ShareSyncStatus {
  /// Server đã khớp với chế độ trên máy (hoặc không có gì cần gửi).
  synced,

  /// Đang chờ gửi (mất mạng hoặc chưa tới lượt).
  pending,

  /// Gửi thất bại; sẽ thử lại.
  failed,
}

/// Đại diện cho một bản ghi hoạt động cá nhân (LOG-03, BR-01).
/// Được lưu trữ offline tại local trước tiên (DAT-01).
class ActivityLog {
  const ActivityLog({
    required this.id,
    required this.eventTypeId,
    required this.name,
    required this.emoji,
    required this.occurredAt,
    this.visibility = ShareVisibility.private,
    this.syncStatus = ShareSyncStatus.synced,
  });

  /// UUID v4, cũng là id của bản chia sẻ trên server (PUT /api/shares/:id, BR-04).
  final String id;
  final String eventTypeId;
  final String name;
  final String emoji;
  final DateTime occurredAt;
  final ShareVisibility visibility;
  final ShareSyncStatus syncStatus;

  bool get isPublic => visibility == ShareVisibility.public;

  ActivityLog copyWith({
    ShareVisibility? visibility,
    ShareSyncStatus? syncStatus,
  }) {
    return ActivityLog(
      id: id,
      eventTypeId: eventTypeId,
      name: name,
      emoji: emoji,
      occurredAt: occurredAt,
      visibility: visibility ?? this.visibility,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'eventTypeId': eventTypeId,
        'name': name,
        'emoji': emoji,
        'occurredAt': occurredAt.toUtc().toIso8601String(),
        'visibility': visibility.name,
        'syncStatus': syncStatus.name,
      };

  /// Bản ghi lưu từ phiên bản cũ (trường `isSharedOnline`) chưa từng được gửi lên server,
  /// nên được đọc lại là Private.
  factory ActivityLog.fromJson(Map<String, dynamic> json) => ActivityLog(
        id: json['id'] as String,
        eventTypeId: json['eventTypeId'] as String,
        name: json['name'] as String,
        emoji: json['emoji'] as String,
        occurredAt: DateTime.parse(json['occurredAt'] as String),
        visibility: ShareVisibility.values.asNameMap()[json['visibility']] ?? ShareVisibility.private,
        syncStatus: ShareSyncStatus.values.asNameMap()[json['syncStatus']] ?? ShareSyncStatus.synced,
      );
}
