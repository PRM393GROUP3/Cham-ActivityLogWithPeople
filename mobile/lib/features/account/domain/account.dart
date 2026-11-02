/// Tài khoản ẩn danh của thiết bị, chỉ dùng cho tính năng xã hội (bạn bè, chia sẻ).
/// Nhật ký cá nhân không cần tài khoản (DAT-01).
class Account {
  const Account({
    required this.id,
    required this.displayName,
    required this.token,
    this.username,
    this.avatarEmoji,
    this.avatarUrl,
  });

  final String id;
  final String displayName;

  /// Tên người dùng duy nhất (chữ thường); `null` khi chưa đặt. Mã QR cá nhân mã hoá tên này và bạn bè
  /// kết bạn bằng nó (SOC-01).
  final String? username;

  /// Avatar là một emoji, hoặc ảnh đã tải lên ([avatarUrl]); cả hai `null` = hiện chữ cái đầu của tên.
  final String? avatarEmoji;

  /// Đường dẫn ảnh avatar trên server (`/api/avatars/...`); có ảnh thì không có emoji.
  final String? avatarUrl;

  /// Bearer token do server cấp khi đăng ký.
  final String token;

  Account copyWith({
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
        token: token,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'displayName': displayName,
        if (username != null) 'username': username,
        if (avatarEmoji != null) 'avatarEmoji': avatarEmoji,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
        'token': token,
      };

  factory Account.fromJson(Map<String, dynamic> json) => Account(
        id: json['id'] as String,
        displayName: json['displayName'] as String,
        username: json['username'] as String?,
        avatarEmoji: json['avatarEmoji'] as String?,
        avatarUrl: json['avatarUrl'] as String?,
        token: json['token'] as String,
      );
}

/// Hồ sơ server trả về sau khi sửa (`PATCH /api/me`, `PUT|DELETE /api/me/avatar`), không gồm token.
typedef Profile = ({String displayName, String? username, String? avatarEmoji, String? avatarUrl});
