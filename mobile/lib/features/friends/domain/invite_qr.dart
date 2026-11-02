import '../../account/domain/username.dart';

/// Nội dung mã QR cá nhân: `CHAM:@<tên người dùng>` (SOC-01). QR chỉ chứa tên người dùng, không chứa
/// nhật ký (NFR-02). Tiền tố giúp nhận ra ngay khi người dùng quét nhầm một mã QR khác (link web,
/// mã thanh toán…).
abstract final class InviteQr {
  static const prefix = 'CHAM:';

  static String encode(String username) => '$prefix@$username';

  /// Lấy tên người dùng (chữ thường) từ nội dung quét được hoặc gõ tay: `CHAM:@ten`, `@ten` hay `ten`,
  /// không phân biệt hoa thường. Trả `null` nếu không phải tên người dùng hợp lệ.
  static String? decode(String? raw) {
    if (raw == null) return null;
    var value = raw.trim();
    if (value.toUpperCase().startsWith(prefix)) value = value.substring(prefix.length).trim();
    if (value.startsWith('@')) value = value.substring(1);
    return usernameError(value) == null ? normalizeUsername(value) : null;
  }
}
