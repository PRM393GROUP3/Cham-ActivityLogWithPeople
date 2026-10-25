class QrCodeData {
  const QrCodeData({
    required this.displayName,
    required this.username,
    required this.inviteCode,
    this.avatarUrl,
    this.instruction = 'Đưa mã này để bạn bè quét kết nối một chạm.',
  });

  final String displayName;
  final String username;
  final String inviteCode;
  final String? avatarUrl;
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
      instruction: instruction ?? this.instruction,
    );
  }
}

