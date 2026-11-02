import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/time/vn_time.dart';
import '../../../activity_dial/domain/activity_log.dart';
import '../../../activity_dial/presentation/activity_dial_controller.dart';
import '../../../activity_dial/presentation/widgets/log_tile.dart';

/// Bộ lọc của màn Lịch sử: tất cả, chỉ bản Công khai, chỉ bản có ghi chú, hoặc một loại sự kiện.
sealed class _Filter {
  const _Filter();
  bool matches(ActivityLog log);
}

class _All extends _Filter {
  const _All();
  @override
  bool matches(ActivityLog log) => true;
}

class _Public extends _Filter {
  const _Public();
  @override
  bool matches(ActivityLog log) => log.isPublic;
}

class _WithNote extends _Filter {
  const _WithNote();
  @override
  bool matches(ActivityLog log) => log.hasNote;
}

class _OfType extends _Filter {
  const _OfType(this.eventTypeId);
  final String eventTypeId;
  @override
  bool matches(ActivityLog log) => log.eventTypeId == eventTypeId;
  @override
  bool operator ==(Object other) => other is _OfType && other.eventTypeId == eventTypeId;
  @override
  int get hashCode => eventTypeId.hashCode;
}

/// Màn Lịch sử: mọi lần chấm, mới nhất trước, nhóm theo ngày giờ Việt Nam (HIS-01, HIS-02).
/// Mỗi dòng sửa được ghi chú, chế độ chia sẻ và xoá như ở "Nhật ký hôm nay".
class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key, this.onNavigateToHome});

  /// Có khi nằm trong shell vuốt: nút ở góc trái đưa về Trang chủ.
  final VoidCallback? onNavigateToHome;

  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  _Filter _filter = const _All();

  /// Ngày (giờ treo tường VN) chọn từ lịch: chỉ hiện từ ngày đó trở về trước.
  DateTime? _untilDay;

  static const _weekdays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

  String _dayLabel(DateTime day) {
    final now = VnTime.now();
    final diff = DateTime.utc(now.year, now.month, now.day).difference(day).inDays;
    if (diff == 0) return 'Hôm nay';
    if (diff == 1) return 'Hôm qua';
    return '${_weekdays[day.weekday - 1]} · ${DateFormat(day.year == now.year ? 'dd/MM' : 'dd/MM/yyyy').format(day)}';
  }

  Future<void> _pickDay(DateTime first) async {
    final now = VnTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _untilDay == null ? today : DateTime(_untilDay!.year, _untilDay!.month, _untilDay!.day),
      firstDate: first.isAfter(today) ? today : first,
      lastDate: today,
      helpText: 'Xem từ ngày',
    );
    if (picked != null) {
      setState(() => _untilDay = DateTime.utc(picked.year, picked.month, picked.day));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(activityDialControllerProvider);
    final all = [...state.logs]..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));

    // Chip loại sự kiện: chỉ những loại có trong lịch sử, theo thứ tự trên Trang chủ.
    final order = {for (final (i, t) in state.eventTypes.indexed) t.id: i};
    final types = <String, ActivityLog>{};
    for (final l in all) {
      types.putIfAbsent(l.eventTypeId, () => l);
    }
    final typeChips = types.values.toList()
      ..sort((a, b) => (order[a.eventTypeId] ?? 1 << 20).compareTo(order[b.eventTypeId] ?? 1 << 20));

    final until = _untilDay?.add(const Duration(days: 1));
    final visible = [
      for (final l in all)
        if (_filter.matches(l) && (until == null || VnTime.of(l.occurredAt).isBefore(until))) l,
    ];

    // Danh sách phẳng: tiêu đề ngày (DateTime) xen giữa các bản ghi (ActivityLog).
    final items = <Object>[];
    final counts = <DateTime, int>{};
    for (final l in visible) {
      final vn = VnTime.of(l.occurredAt);
      final day = DateTime.utc(vn.year, vn.month, vn.day);
      if (counts[day] == null) items.add(day);
      counts[day] = (counts[day] ?? 0) + 1;
      items.add(l);
    }

    Widget chip(String label, _Filter filter) => Padding(
          padding: const EdgeInsets.only(right: 6),
          child: ChoiceChip(
            label: Text(label),
            selected: _filter == filter,
            showCheckmark: false,
            onSelected: (_) => setState(() => _filter = filter),
          ),
        );

    return Scaffold(
      backgroundColor: const Color(0xFFFAF6F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF6F0),
        leading: widget.onNavigateToHome == null
            ? null
            : IconButton(
                tooltip: 'Trang chủ',
                icon: const Icon(Icons.chevron_left_rounded),
                onPressed: widget.onNavigateToHome,
              ),
        title: const Text('Lịch sử', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            tooltip: 'Chọn ngày',
            icon: const Icon(Icons.calendar_month_outlined),
            onPressed: all.isEmpty ? null : () => _pickDay(VnTime.of(all.last.occurredAt)),
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 44,
            child: ListView(
              key: const ValueKey('history-filters'),
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                if (_untilDay != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: InputChip(
                      label: Text('Đến ${DateFormat('dd/MM').format(_untilDay!)}'),
                      onDeleted: () => setState(() => _untilDay = null),
                    ),
                  ),
                chip('Tất cả', const _All()),
                chip('Công khai', const _Public()),
                chip('Có ghi chú', const _WithNote()),
                for (final l in typeChips) chip('${l.emoji} ${l.name}', _OfType(l.eventTypeId)),
              ],
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? const Center(
                    child: Text(
                      'Chưa có lần chấm nào',
                      style: TextStyle(fontSize: 14, color: Color(0xFF6E6259)),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      if (item is DateTime) {
                        return Padding(
                          padding: EdgeInsets.fromLTRB(2, index == 0 ? 4 : 14, 2, 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _dayLabel(item),
                                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800),
                                ),
                              ),
                              Text(
                                '${counts[item]}',
                                style: const TextStyle(fontSize: 12.5, color: Color(0xFF8A7E74)),
                              ),
                            ],
                          ),
                        );
                      }
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: LogTile(log: item as ActivityLog),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
