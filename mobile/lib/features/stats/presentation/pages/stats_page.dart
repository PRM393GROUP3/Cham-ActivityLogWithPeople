import 'dart:ui' show ImageByteFormat;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/time/vn_time.dart';
import '../../../../core/utils/image_saver/image_saver.dart';
import '../../../account/presentation/account_controller.dart';
import '../../../activity_dial/domain/activity_log.dart';
import '../../../activity_dial/presentation/activity_dial_controller.dart';
import '../../domain/activity_stats.dart';
import '../widgets/bar_chart.dart';
import '../widgets/recap_card.dart';

/// Màn Phân tích: quy luật sinh hoạt theo ngày / tuần / tháng (STA-01, STA-02). Chỉ có số liệu
/// tổng hợp; từng lần chấm nằm ở màn Lịch sử. Tính theo giờ Việt Nam; tuần bắt đầu Thứ Hai.
class StatsPage extends ConsumerStatefulWidget {
  const StatsPage({super.key, this.initialPeriod = StatsPeriod.week, this.onNavigateToHome});

  final StatsPeriod initialPeriod;

  /// Có khi nằm trong shell vuốt: nút ở góc phải đưa về Trang chủ.
  final VoidCallback? onNavigateToHome;

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

  /// Xem trước thẻ tóm tắt khoảng đang xem và lưu thành ảnh PNG (STA-02).
  void _openRecap(ActivityStats stats) {
    final account = ref.read(accountControllerProvider).value;
    final cardKey = GlobalKey();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFFFFDF9),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FittedBox(
                child: RepaintBoundary(
                  key: cardKey,
                  child: RecapCard(
                    stats: stats,
                    rangeLabel: _rangeLabel,
                    displayName: account?.displayName ?? AccountController.defaultDisplayName,
                    avatarEmoji: account?.avatarEmoji,
                    avatarUrl: account?.avatarUrl,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFB53216),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('Lưu ảnh'),
                  onPressed: () => _saveRecap(sheetContext, cardKey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveRecap(BuildContext sheetContext, GlobalKey cardKey) async {
    final messenger = ScaffoldMessenger.of(context);
    String message;
    try {
      final boundary = cardKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3);
      final png = await image.toByteData(format: ImageByteFormat.png);
      image.dispose();
      final period = switch (_range.period) {
        StatsPeriod.day => 'ngay',
        StatsPeriod.week => 'tuan',
        StatsPeriod.month => 'thang',
      };
      message = await ref.read(pngSaverProvider)(
        png!.buffer.asUint8List(),
        fileName: 'cham-$period-${DateFormat('yyyyMMdd').format(_range.start)}',
      );
      if (sheetContext.mounted) Navigator.pop(sheetContext);
    } on StateError catch (e) {
      message = e.message;
    } catch (_) {
      message = 'Không lưu được ảnh.';
    }
    messenger.showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    final allLogs = ref.watch(activityDialControllerProvider).logs;
    final stats = ActivityStats(_range, allLogs);
    final previous = ActivityStats(_range.previous(), allLogs);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF6F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF6F0),
        automaticallyImplyLeading: widget.onNavigateToHome == null,
        title: const Text('Phân tích', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            key: const ValueKey('open-recap'),
            tooltip: 'Tạo ảnh tóm tắt',
            icon: const Icon(Icons.auto_awesome_mosaic_outlined),
            onPressed: stats.total == 0 ? null : () => _openRecap(stats),
          ),
          if (widget.onNavigateToHome != null)
            IconButton(
              tooltip: 'Trang chủ',
              icon: const Icon(Icons.chevron_right_rounded),
              onPressed: widget.onNavigateToHome,
            ),
        ],
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
            // Đổi Ngày/Tuần/Tháng giữ nguyên ngày đang xem; nếu đang xem khoảng chứa hôm nay thì lấy
            // hôm nay (tuần 26/10–01/11 chuyển sang Tháng phải là tháng 11, không phải tháng 10).
            onSelectionChanged: (s) => setState(
              () => _range = StatsRange.containing(s.first, _range.isCurrentOrFuture ? VnTime.now() : _range.start),
            ),
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
          if (stats.total == 0)
            const _Card(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'Chưa có lần chấm nào',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Color(0xFF6E6259)),
                ),
              ),
            )
          else ...[
            _kpis(stats, previous),
            _highlights(stats, previous, allLogs),
            _Section(
              title: 'Theo loại',
              child: Column(
                children: [
                  for (final t in stats.byType) _TypeRow(type: t, max: stats.byType.first.count),
                ],
              ),
            ),
            if (_range.period != StatsPeriod.day)
              _Section(
                title: 'Theo ngày',
                child: SimpleBarChart(
                  values: stats.byDay,
                  highlightIndex: _todayIndex,
                  labels: _range.period == StatsPeriod.week
                      ? _weekdays
                      : [for (var d = 1; d <= _range.dayCount; d++) d == 1 || d % 5 == 0 ? '$d' : null],
                ),
              ),
            _Section(
              title: 'Theo giờ',
              child: SimpleBarChart(
                values: stats.byHour,
                labels: [for (var h = 0; h < 24; h++) h % 6 == 0 ? '${h}h' : null],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Bốn ô số liệu: tổng (so với kỳ trước), trung bình / ngày, giờ cao điểm, ngày hoặc loại nổi bật.
  Widget _kpis(ActivityStats stats, ActivityStats previous) {
    final String delta;
    if (previous.total == 0) {
      delta = 'kỳ trước: 0';
    } else {
      final pct = ((stats.total - previous.total) * 100 / previous.total).round();
      delta = pct == 0 ? '= kỳ trước' : '${pct > 0 ? '+' : ''}$pct% kỳ trước';
    }
    final hour = stats.peakHour!;
    final day = stats.peakDay!;
    final (lastValue, lastLabel) = switch (_range.period) {
      StatsPeriod.day => (stats.byType.first.emoji, 'nhiều nhất'),
      StatsPeriod.week => (_weekdayNames[day], 'ngày bận nhất'),
      StatsPeriod.month => ('Ngày ${day + 1}', 'ngày bận nhất'),
    };
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 2.1,
        children: [
          _Kpi(value: '${stats.total}', label: 'lần chấm · $delta', accent: true),
          _Kpi(value: stats.averagePerDay.toStringAsFixed(1).replaceAll('.', ','), label: 'mỗi ngày'),
          _Kpi(value: '${hour}h–${hour + 1}h', label: 'giờ cao điểm'),
          _Kpi(value: lastValue, label: lastLabel),
        ],
      ),
    );
  }

  /// Tối đa 3 dòng ngắn: loại nhiều nhất, loại tăng mạnh nhất so với kỳ trước, loại lâu chưa chấm.
  Widget _highlights(ActivityStats stats, ActivityStats previous, List<ActivityLog> allLogs) {
    final rows = <(String, String, String)>[];
    final top = stats.byType.first;
    rows.add((top.emoji, top.name, 'nhiều nhất'));

    final before = {for (final t in previous.byType) t.eventTypeId: t.count};
    TypeCount? rising;
    var rise = 0;
    for (final t in stats.byType) {
      final d = t.count - (before[t.eventTypeId] ?? 0);
      if (d > rise && t.eventTypeId != top.eventTypeId) (rising, rise) = (t, d);
    }
    if (rising != null) rows.add((rising.emoji, rising.name, '+$rise'));

    if (_range.isCurrentOrFuture) {
      final today = VnTime.now();
      ActivityLog? stale;
      var staleDays = 0;
      for (final l in latestByType(allLogs).values) {
        final at = VnTime.of(l.occurredAt);
        final days = DateTime.utc(today.year, today.month, today.day)
            .difference(DateTime.utc(at.year, at.month, at.day))
            .inDays;
        if (days >= 3 && days <= 30 && days > staleDays) (stale, staleDays) = (l, days);
      }
      if (stale != null) rows.add((stale.emoji, stale.name, '$staleDays ngày chưa chấm'));
    }

    return _Section(
      title: 'Điểm nhấn',
      child: Column(
        children: [
          for (final (emoji, name, note) in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  SizedBox(width: 30, child: Text(emoji, style: const TextStyle(fontSize: 18))),
                  Expanded(
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Text(note, style: const TextStyle(fontSize: 12.5, color: Color(0xFF8A7E74))),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Kpi extends StatelessWidget {
  const _Kpi({required this.value, required this.label, this.accent = false});

  final String value;
  final String label;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDE4D6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: accent ? 26 : 18,
                fontWeight: FontWeight.w900,
                color: accent ? const Color(0xFFB53216) : const Color(0xFF2E241F),
              ),
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11.5, color: Color(0xFF8A7E74)),
          ),
        ],
      ),
    );
  }
}

class _TypeRow extends StatelessWidget {
  const _TypeRow({required this.type, required this.max});

  final TypeCount type;
  final int max;

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
