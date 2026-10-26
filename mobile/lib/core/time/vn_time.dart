import 'package:intl/intl.dart';

/// Giờ Việt Nam (UTC+7) dùng cho mọi hiển thị, lịch sử theo ngày và thống kê,
/// bất kể múi giờ cài trên máy (DAT-02).
abstract final class VnTime {
  static const offset = Duration(hours: 7);

  /// Thời điểm [t] biểu diễn theo giờ treo tường Việt Nam (DateTime UTC đã cộng 7 giờ),
  /// dùng để lấy ngày/giờ hoặc format. Không dùng giá trị này để lưu hay gửi lên server.
  static DateTime of(DateTime t) => t.toUtc().add(offset);

  static DateTime now() => of(DateTime.now());

  static bool isSameDay(DateTime a, DateTime b) {
    final x = of(a), y = of(b);
    return x.year == y.year && x.month == y.month && x.day == y.day;
  }

  static bool isToday(DateTime t) => isSameDay(t, DateTime.now());

  static String hm(DateTime t) => DateFormat('HH:mm').format(of(t));

  /// "vừa xong", "15 phút trước", "3 giờ trước", "Hôm qua 21:30", "12/10 08:00".
  static String relative(DateTime t, {DateTime? now}) {
    final current = now ?? DateTime.now();
    final diff = current.difference(t);
    if (diff.inMinutes < 1) return 'vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (isSameDay(t, current)) return '${diff.inHours} giờ trước';
    if (isSameDay(t, current.subtract(const Duration(days: 1)))) return 'Hôm qua ${hm(t)}';
    return DateFormat('dd/MM HH:mm').format(of(t));
  }
}
