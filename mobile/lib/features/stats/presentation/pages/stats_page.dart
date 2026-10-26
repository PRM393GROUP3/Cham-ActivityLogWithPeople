import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/time/vn_time.dart';
import '../../../activity_dial/presentation/activity_dial_controller.dart';
import '../../../activity_dial/presentation/widgets/log_tile.dart';
import '../../domain/activity_stats.dart';
import '../widgets/bar_chart.dart';

/// Lịch sử theo ngày / tuần / tháng và thống kê quy luật sinh hoạt (HIS-01, HIS-02, STA-01).
/// Tính theo giờ Việt Nam; tuần bắt đầu Thứ Hai; khung giờ 1 tiếng. Hoạt động offline.
class StatsPage extends ConsumerStatefulWidget {
  const StatsPage({super.key, this.initialPeriod = StatsPeriod.day});

  final StatsPeriod initialPeriod;

  @override
  ConsumerState<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends ConsumerState<StatsPage> {
  late StatsRange _range = StatsRange.current(widget.initialPeriod);

  static const _weekdays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
  static const _weekdayNames = ['Thứ Hai', 'Thứ Ba', 'Thứ Tư', 'Thứ Năm', 'Thứ Sáu', 'Thứ Bảy', 'Chủ Nhật'];

  String get _rangeLabel {
    final r = _range;
    final current = r.isCurrentOrFuture;
    return switch (r.period) {
      StatsPeriod.day => current
          ? 'Hôm nay, ${DateFormat('dd/MM/yyyy').format(r.start)}'
          : '${_weekdayNames[r.start.weekday - 1]}, ${DateFormat('dd/MM/yyyy').format(r.start)}',
      StatsPeriod.week =>
        '${current ? 'Tuần này · ' : ''}${DateFormat('dd/MM').format(r.start)} – '
            '${DateFormat('dd/MM/yyyy').format(r.end.subtract(const Duration(days: 1)))}',
      StatsPeriod.month => '${current ? 'Tháng này · ' : ''}Tháng ${r.start.month}/${r.start.year}',
    };
  }

  /// Vị trí "hôm nay" trong biểu đồ theo ngày, nếu khoảng đang xem chứa hôm nay.
  int? get _todayIndex {
    final today = VnTime.now();
    final day = DateTime.utc(today.year, today.month, today.day);
    final index = day.difference(_range.start).inDays;
    return index >= 0 && index < _range.dayCount ? index : null;
  }

  @override
  Widget build(BuildContext context) {
    final allLogs = ref.watch(activityDialControllerProvider).logs;
    final stats = ActivityStats(_range, allLogs);
    final latest = latestByType(allLogs);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF6F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF6F0),
        title: const Text('Lịch sử & thống kê', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          SegmentedButton<StatsPeriod>(
            segments: const [
              ButtonSegment(value: StatsPeriod.day, label: Text('Ngày')),
              ButtonSegment(value: StatsPeriod.week, label: Text('Tuần')),
              ButtonSegment(value: StatsPeriod.month, label: Text('Tháng')),
            ],
            selected: {_range.period},
            showSelectedIcon: false,
            onSelectionChanged: (s) => setState(() => _range = StatsRange.containing(s.first, _range.start)),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                tooltip: 'Trước',
                icon: const Icon(Icons.chevron_left_rounded),
                onPressed: () => setState(() => _range = _range.previous()),
              ),
              Expanded(
                child: Text(
                  _rangeLabel,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                tooltip: 'Sau',
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed: _range.isCurrentOrFuture ? null : () => setState(() => _range = _range.next()),
              ),
            ],
          ),
          _Card(
            child: Row(
              children: [
                Text(
                  '${stats.total}',
                  style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Color(0xFFB53216)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    stats.total == 0 ? 'Chưa có lần chấm nào' : 'lần chấm · ${stats.byType.length} loại sự kiện',
                    style: const TextStyle(fontSize: 14, color: Color(0xFF6E6259)),
                  ),
                ),
              ],
            ),
          ),
          if (stats.total > 0) ...[
            _Section(
              title: 'Theo loại sự kiện',
              child: Column(
                children: [
                  for (final t in stats.byType)
                    _TypeRow(type: t, max: stats.byType.first.count, latest: latest[t.eventTypeId]?.occurredAt),
                ],
              ),
            ),
            if (_range.period != StatsPeriod.day)
              _Section(
                title: _range.period == StatsPeriod.week ? 'Theo ngày trong tuần' : 'Theo ngày trong tháng',
                child: SimpleBarChart(
                  values: stats.byDay,
                  highlightIndex: _todayIndex,
                  labels: _range.period == StatsPeriod.week
                      ? _weekdays
                      : [for (var d = 1; d <= _range.dayCount; d++) d == 1 || d % 5 == 0 ? '$d' : null],
                ),
              ),
            _Section(
              title: 'Theo khung giờ',
              child: SimpleBarChart(
                values: stats.byHour,
                labels: [for (var h = 0; h < 24; h++) h % 6 == 0 ? '${h}h' : null],
              ),
            ),
            _Section(
              title: 'Các lần chấm',
              child: Column(
                children: [
                  for (final log in stats.logs)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: LogTile(log: log, showDate: _range.period != StatsPeriod.day),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TypeRow extends StatelessWidget {
  const _TypeRow({required this.type, required this.max, required this.latest});

  final TypeCount type;
  final int max;
  final DateTime? latest;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(width: 30, child: Text(type.emoji, style: const TextStyle(fontSize: 20))),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        type.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Text('${type.count}', style: const TextStyle(fontWeight: FontWeight.w800)),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: type.count / max,
                    minHeight: 6,
                    backgroundColor: const Color(0xFFEDE4D6),
                    color: const Color(0xFFF08A6E),
                  ),
                ),
                if (latest != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Gần nhất: ${VnTime.relative(latest!)}',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF8A7E74)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEDE4D6)),
      ),
      child: child,
    );
  }
}
