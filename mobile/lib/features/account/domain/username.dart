/// Ký tự được gõ trong ô tên người dùng (chữ hoa được đổi thành chữ thường khi gửi).
final usernameAllowedChars = RegExp(r'[a-zA-Z0-9._]');

const usernameMaxLength = 20;

final _usernamePattern = RegExp(r'^(?!\.)(?!.*\.\.)[a-z0-9._]{3,20}(?<!\.)$');

/// Tên người dùng như server lưu: bỏ khoảng trắng, chữ thường.
String normalizeUsername(String value) => value.trim().toLowerCase();

/// Lỗi hiển thị cho [value], hoặc `null` nếu hợp lệ. Server kiểm tra lại cùng quy tắc.
String? usernameError(String value) {
  final v = normalizeUsername(value);
  if (v.isEmpty) return 'Hãy chọn một tên người dùng.';
  if (v.length < 3 || v.length > usernameMaxLength) return 'Tên người dùng dài 3–$usernameMaxLength ký tự.';
  if (!_usernamePattern.hasMatch(v)) {
    return 'Chỉ dùng chữ không dấu, số, "." và "_"; không bắt đầu, kết thúc bằng "." hay có "..".';
  }
  return null;
}
