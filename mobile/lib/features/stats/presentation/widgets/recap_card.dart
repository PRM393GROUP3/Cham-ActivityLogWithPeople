import 'dart:math';

import 'package:flutter/material.dart';

import '../../../account/presentation/widgets/user_avatar.dart';
import '../../domain/activity_stats.dart';

/// Thẻ tóm tắt một ngày / tuần / tháng để lưu thành ảnh và chia sẻ (STA-02): tổng số chấm,
/// ba hoạt động nhiều nhất và biểu đồ nhỏ. Kích thước cố định để ảnh xuất ra luôn giống nhau.
class RecapCard extends StatelessWidget {
  const RecapCard({
    super.key,
    required this.stats,
    required this.rangeLabel,
    required this.displayName,
    this.avatarEmoji,
  });

  final ActivityStats stats;
  final String rangeLabel;
  final String displayName;
  final String? avatarEmoji;

  static const size = Size(340, 460);
  static const _weekdays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

  String get _title => switch (stats.range.period) {
    StatsPeriod.day => 'Ngày của tôi',
    StatsPeriod.week => 'Tuần của tôi',
    StatsPeriod.month => 'Tháng của tôi',
  };

  @override
  Widget build(BuildContext context) {
    final top = stats.byType.take(3).toList();
    final bars = stats.range.period == StatsPeriod.day ? stats.byHour : stats.byDay;
    final barLabels = switch (stats.range.period) {
      StatsPeriod.day => [for (var h = 0; h < 24; h++) h % 6 == 0 ? '${h}h' : ''],
      StatsPeriod.week => _weekdays,
      StatsPeriod.month => [for (var d = 1; d <= bars.length; d++) d == 1 || d % 10 == 0 ? '$d' : ''],
    };

    return SizedBox.fromSize(
      size: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFF8A65), Color(0xFFB53216)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _title,
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
              ),
              Text(rangeLabel, style: const TextStyle(color: Color(0xFFFFE3D8), fontSize: 13)),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${stats.total}',
                    style: const TextStyle(color: Colors.white, fontSize: 56, height: 1, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(width: 8),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 6),
                    child: Text(
                      'chấm',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              for (final t in top)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(color: Color(0x33FFFFFF), shape: BoxShape.circle),
                        child: Text(t.emoji, style: const TextStyle(fontSize: 18)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          t.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                      ),
                      Text(
                        '${t.count} lần',
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              const Spacer(),
              SizedBox(
                height: 64,
                child: _MiniBars(values: bars, labels: barLabels),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  UserAvatar(name: displayName, emoji: avatarEmoji, radius: 14, backgroundColor: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const Text(
                    'Chấm',
                    style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900),
                  ),
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(left: 3, top: 6),
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniBars extends StatelessWidget {
  const _MiniBars({required this.values, required this.labels});

  final List<int> values;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final peak = max(1, values.fold(0, max));
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 0; i < values.length; i++)
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: values.length > 12 ? 1 : 3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    height: 4 + 40 * values[i] / peak,
                    decoration: BoxDecoration(
                      color: values[i] == peak && values[i] > 0 ? Colors.white : const Color(0x88FFFFFF),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 12,
                    child: OverflowBox(
                      maxWidth: 30,
                      child: Text(labels[i], style: const TextStyle(color: Color(0xFFFFE3D8), fontSize: 9.5)),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
