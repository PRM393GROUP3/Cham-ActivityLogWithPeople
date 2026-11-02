/// Tài khoản ẩn danh của thiết bị, chỉ dùng cho tính năng xã hội (bạn bè, chia sẻ).
/// Nhật ký cá nhân không cần tài khoản (DAT-01).
class Account {
  const Account({
    required this.id,
    required this.displayName,
    required this.inviteCode,
    required this.token,
    this.username,
    this.avatarEmoji,
    this.avatarUrl,
  });

  final String id;
  final String displayName;

  /// Tên người dùng duy nhất (chữ thường); `null` khi chưa đặt.
  final String? username;

  /// Avatar là một emoji, hoặc ảnh đã tải lên ([avatarUrl]); cả hai `null` = hiện chữ cái đầu của tên.
  final String? avatarEmoji;

  /// Đường dẫn ảnh avatar trên server (`/api/avatars/...`); có ảnh thì không có emoji.
  final String? avatarUrl;

  /// Mã được mã hoá trong QR cá nhân (SOC-01).
  final String inviteCode;

  /// Bearer token do server cấp khi đăng ký.
  final String token;

  Account copyWith({
    String? inviteCode,
    String? displayName,
    String? username,
    String? Function()? avatarEmoji,
    String? Function()? avatarUrl,
  }) =>
      Account(
        id: id,
        displayName: displayName ?? this.displayName,
        username: username ?? this.username,
        avatarEmoji: avatarEmoji != null ? avatarEmoji() : this.avatarEmoji,
        avatarUrl: avatarUrl != null ? avatarUrl() : this.avatarUrl,
        inviteCode: inviteCode ?? this.inviteCode,
        token: token,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'displayName': displayName,
        if (username != null) 'username': username,
        if (avatarEmoji != null) 'avatarEmoji': avatarEmoji,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
        'inviteCode': inviteCode,
        'token': token,
      };

  factory Account.fromJson(Map<String, dynamic> json) => Account(
        id: json['id'] as String,
        displayName: json['displayName'] as String,
        username: json['username'] as String?,
        avatarEmoji: json['avatarEmoji'] as String?,
        avatarUrl: json['avatarUrl'] as String?,
        inviteCode: json['inviteCode'] as String,
        token: json['token'] as String,
      );
}

/// Hồ sơ server trả về sau khi sửa (`PATCH /api/me`, `PUT|DELETE /api/me/avatar`), không gồm token.
typedef Profile = ({String displayName, String? username, String? avatarEmoji, String? avatarUrl});
