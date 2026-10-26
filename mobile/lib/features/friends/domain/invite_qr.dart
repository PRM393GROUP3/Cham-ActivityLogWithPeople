/// Nội dung mã QR cá nhân: `CHAM:<mã mời>` (SOC-01). QR chỉ chứa mã mời, không chứa nhật ký (NFR-02).
/// Tiền tố giúp nhận ra ngay khi người dùng quét nhầm một mã QR khác (link web, mã thanh toán…).
abstract final class InviteQr {
  static const prefix = 'CHAM:';

  /// Bảng ký tự của mã mời (khớp backend: bỏ 0/O/1/I để gõ tay không nhầm), 10 ký tự.
  static final _code = RegExp(r'^[2-9A-HJ-NP-Z]{10}$');

  static String encode(String inviteCode) => '$prefix$inviteCode';

  /// Lấy mã mời từ nội dung quét được (`CHAM:XXXXXXXXXX` hoặc mã trần 10 ký tự, không phân biệt
  /// hoa thường, bỏ khoảng trắng). Trả `null` nếu không phải mã của Chấm.
  static String? decode(String? raw) {
    if (raw == null) return null;
    var value = raw.trim().toUpperCase().replaceAll(RegExp(r'\s'), '');
    if (value.startsWith(prefix)) value = value.substring(prefix.length);
    return _code.hasMatch(value) ? value : null;
  }
}
