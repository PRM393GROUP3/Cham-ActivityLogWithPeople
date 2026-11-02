class QrCodeData {
  const QrCodeData({
    required this.displayName,
    required this.username,
    this.avatarUrl,
    this.avatarEmoji,
    this.instruction = 'Đưa mã này để bạn bè quét kết nối một chạm.',
  });

  final String displayName;

  /// Tên người dùng (không có `@`); mã QR mã hoá chính nó.
  final String username;
  final String? avatarUrl;

  /// Avatar emoji của tài khoản (có ảnh [avatarUrl] thì không có emoji).
  final String? avatarEmoji;
  final String instruction;
}
