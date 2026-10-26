import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/time/vn_time.dart';
import '../activity_dial_controller.dart';
import 'log_tile.dart';
import '../../domain/activity_log.dart';

/// Modal BottomSheet xem chi tiết các lần chấm trong ngày hôm nay (HIS-01).
/// Cho phép xoá bản ghi (HIS-02, LOG-04: không Undo, chỉ Delete) và đổi chế độ chia sẻ
/// Riêng tư / Công khai trên từng bản ghi (SOC-03, SOC-04).
class TodayLogsSheet extends ConsumerWidget {
  const TodayLogsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(activityDialControllerProvider);
    final controller = ref.read(activityDialControllerProvider.notifier);
    final logs = state.todayLogs;
    final hasUnsent = logs.any((l) => l.syncStatus == ShareSyncStatus.failed);

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFFFDF9),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thanh kéo (drag handle)
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD6CBC0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Flexible(
                      child: Text(
                        'Nhật ký hôm nay',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF261E1A),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDEEE8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${logs.length} chấm',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFFF5733),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasUnsent)
                    TextButton.icon(
                      onPressed: controller.syncShares,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Thử lại'),
                    ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Color(0xFF6E6259),
                    ),
                  ),
                ],
              ),
            ],
          ),

          if (state.latestLog != null) ...[
            const SizedBox(height: 4),
            Text(
              'Lần chấm gần nhất: ${state.latestLog!.name} (${VnTime.hm(state.latestLog!.occurredAt)})',
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: Color(0xFF7E7369),
              ),
            ),
          ],

          const Divider(height: 24, color: Color(0xFFEBE0D2)),

          // Danh sách các bản ghi
          if (logs.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 36),
              child: Center(
                child: Text(
                  'Hôm nay chưa có lần chấm nào.\nHãy chạm vào một nút trên vòng xoay!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF948A80),
                    height: 1.4,
                  ),
                ),
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: logs.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final log = logs[index];
                  return LogTile(log: log);
                },
              ),
            ),
          const SizedBox(height: 8),
          Center(
            child: TextButton.icon(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/stats');
              },
              icon: const Icon(Icons.bar_chart_rounded, size: 18),
              label: const Text('Xem lịch sử & thống kê'),
            ),
          ),
        ],
      ),
    );
  }
}
