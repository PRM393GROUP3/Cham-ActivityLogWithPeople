/// Tài khoản ẩn danh của thiết bị, chỉ dùng cho tính năng xã hội (bạn bè, chia sẻ).
/// Nhật ký cá nhân không cần tài khoản (DAT-01).
class Account {
  const Account({
    required this.id,
    required this.displayName,
    required this.inviteCode,
    required this.token,
    this.avatarEmoji,
  });

  final String id;
  final String displayName;

  /// Avatar là một emoji; `null` = hiện chữ cái đầu của tên.
  final String? avatarEmoji;

  /// Mã được mã hoá trong QR cá nhân (SOC-01).
  final String inviteCode;

  /// Bearer token do server cấp khi đăng ký.
  final String token;

  Account copyWith({String? inviteCode, String? displayName, String? Function()? avatarEmoji}) => Account(
        id: id,
        displayName: displayName ?? this.displayName,
        avatarEmoji: avatarEmoji != null ? avatarEmoji() : this.avatarEmoji,
        inviteCode: inviteCode ?? this.inviteCode,
        token: token,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'displayName': displayName,
        if (avatarEmoji != null) 'avatarEmoji': avatarEmoji,
        'inviteCode': inviteCode,
        'token': token,
      };

  factory Account.fromJson(Map<String, dynamic> json) => Account(
        id: json['id'] as String,
        displayName: json['displayName'] as String,
        avatarEmoji: json['avatarEmoji'] as String?,
        inviteCode: json['inviteCode'] as String,
        token: json['token'] as String,
      );
}

/// Kết quả `PATCH /api/me` (không gồm token).
typedef Profile = ({String displayName, String? avatarEmoji});
