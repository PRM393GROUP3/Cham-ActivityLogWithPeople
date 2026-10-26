import '../../../core/time/vn_time.dart';
import '../../activity_dial/domain/activity_log.dart';

/// Khoảng thời gian xem lịch sử / thống kê (HIS-01, STA-01).
enum StatsPeriod { day, week, month }

/// Một khoảng [start, end) tính theo **ngày giờ Việt Nam** (DAT-02). [start] và [end] là DateTime UTC
/// biểu diễn nửa đêm giờ VN dạng "giờ treo tường" (cùng quy ước với [VnTime.of]).
class StatsRange {
  const StatsRange._(this.period, this.start, this.end);

  final StatsPeriod period;
  final DateTime start;
  final DateTime end;

  /// Khoảng chứa ngày [vnDay] (giờ treo tường VN). Tuần bắt đầu từ Thứ Hai.
  factory StatsRange.containing(StatsPeriod period, DateTime vnDay) {
    final day = DateTime.utc(vnDay.year, vnDay.month, vnDay.day);
    return switch (period) {
      StatsPeriod.day => StatsRange._(period, day, day.add(const Duration(days: 1))),
      StatsPeriod.week => () {
          final monday = day.subtract(Duration(days: day.weekday - DateTime.monday));
          return StatsRange._(period, monday, monday.add(const Duration(days: 7)));
        }(),
      StatsPeriod.month =>
        StatsRange._(period, DateTime.utc(day.year, day.month), DateTime.utc(day.year, day.month + 1)),
    };
  }

  /// Khoảng hiện tại (hôm nay / tuần này / tháng này theo giờ VN).
  factory StatsRange.current(StatsPeriod period) => StatsRange.containing(period, VnTime.now());

  StatsRange previous() => StatsRange.containing(period, start.subtract(const Duration(days: 1)));

  StatsRange next() => StatsRange.containing(period, end);

  /// Số ngày trong khoảng (1, 7 hoặc 28–31).
  int get dayCount => end.difference(start).inDays;

  bool contains(DateTime instant) {
    final vn = VnTime.of(instant);
    return !vn.isBefore(start) && vn.isBefore(end);
  }

  bool get isCurrentOrFuture => !end.isBefore(StatsRange.current(period).end);
}

/// Số lần ghi của một loại sự kiện trong khoảng.
class TypeCount {
  const TypeCount({required this.eventTypeId, required this.emoji, required this.name, required this.count});

  final String eventTypeId;

  /// Emoji / tên của lần ghi gần nhất (bản ghi giữ tên lúc ghi, LOG-05).
  final String emoji;
  final String name;
  final int count;
}

/// Thống kê các bản ghi trong một khoảng (STA-01). Chỉ dựa trên những gì đã ghi.
class ActivityStats {
  ActivityStats(this.range, Iterable<ActivityLog> allLogs)
      : logs = allLogs.where((l) => range.contains(l.occurredAt)).toList()
          ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));

  final StatsRange range;

  /// Bản ghi trong khoảng, mới nhất trước.
  final List<ActivityLog> logs;

  int get total => logs.length;

  /// Số lần ghi theo loại, nhiều nhất trước (cùng số thì theo tên).
  List<TypeCount> get byType {
    final groups = <String, List<ActivityLog>>{};
    for (final l in logs) {
      groups.putIfAbsent(l.eventTypeId, () => []).add(l);
    }
    return [
      for (final e in groups.entries)
        TypeCount(eventTypeId: e.key, emoji: e.value.first.emoji, name: e.value.first.name, count: e.value.length),
    ]..sort((a, b) => b.count != a.count ? b.count.compareTo(a.count) : a.name.compareTo(b.name));
  }

  /// Số lần ghi theo từng khung 1 giờ (0–23) theo giờ VN.
  List<int> get byHour {
    final buckets = List.filled(24, 0);
    for (final l in logs) {
      buckets[VnTime.of(l.occurredAt).hour]++;
    }
    return buckets;
  }

  /// Số lần ghi theo từng ngày trong khoảng (tuần: 7 phần tử từ Thứ Hai; tháng: số ngày của tháng).
  List<int> get byDay {
    final buckets = List.filled(range.dayCount, 0);
    for (final l in logs) {
      final vn = VnTime.of(l.occurredAt);
      buckets[DateTime.utc(vn.year, vn.month, vn.day).difference(range.start).inDays]++;
    }
    return buckets;
  }
}

/// Lần ghi gần nhất của từng loại sự kiện trên toàn bộ lịch sử (HIS-01), theo id loại.
Map<String, ActivityLog> latestByType(Iterable<ActivityLog> logs) {
  final latest = <String, ActivityLog>{};
  for (final l in logs) {
    final current = latest[l.eventTypeId];
    if (current == null || l.occurredAt.isAfter(current.occurredAt)) latest[l.eventTypeId] = l;
  }
  return latest;
}
