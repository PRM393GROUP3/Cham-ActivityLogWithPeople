/// Tài khoản ẩn danh của thiết bị, chỉ dùng cho tính năng xã hội (bạn bè, chia sẻ).
/// Nhật ký cá nhân không cần tài khoản (DAT-01).
class Account {
  const Account({
    required this.id,
    required this.displayName,
    required this.inviteCode,
    required this.token,
  });

  final String id;
  final String displayName;

  /// Mã được mã hoá trong QR cá nhân (SOC-01).
  final String inviteCode;

  /// Bearer token do server cấp khi đăng ký.
  final String token;

  Account copyWith({String? inviteCode}) => Account(
        id: id,
        displayName: displayName,
        inviteCode: inviteCode ?? this.inviteCode,
        token: token,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'displayName': displayName,
        'inviteCode': inviteCode,
        'token': token,
      };

  factory Account.fromJson(Map<String, dynamic> json) => Account(
        id: json['id'] as String,
        displayName: json['displayName'] as String,
        inviteCode: json['inviteCode'] as String,
        token: json['token'] as String,
      );
}
