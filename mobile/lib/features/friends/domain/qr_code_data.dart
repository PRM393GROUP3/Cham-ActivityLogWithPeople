class QrCodeData {
  const QrCodeData({
    required this.displayName,
    required this.username,
    required this.inviteCode,
    this.avatarUrl,
    this.avatarEmoji,
    this.instruction = 'Đưa mã này để bạn bè quét kết nối một chạm.',
  });

  final String displayName;
  final String username;
  final String inviteCode;
  final String? avatarUrl;

  /// Avatar emoji của tài khoản; ưu tiên hơn [avatarUrl].
  final String? avatarEmoji;
  final String instruction;

  QrCodeData copyWith({
    String? displayName,
    String? username,
    String? inviteCode,
    String? avatarUrl,
    String? instruction,
  }) {
    return QrCodeData(
      displayName: displayName ?? this.displayName,
      username: username ?? this.username,
      inviteCode: inviteCode ?? this.inviteCode,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      avatarEmoji: avatarEmoji,
      instruction: instruction ?? this.instruction,
    );
  }
}

