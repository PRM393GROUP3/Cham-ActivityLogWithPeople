import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../activity_dial_controller.dart';
import '../../domain/activity_log.dart';

/// Modal BottomSheet xem chi tiết các lần chấm trong ngày hôm nay (HIS-01).
/// Cho phép xoá bản ghi (HIS-02, LOG-04: không Undo, chỉ Delete).
class TodayLogsSheet extends StatelessWidget {
  const TodayLogsSheet({
    super.key,
    required this.state,
    required this.controller,
  });

  final ActivityDialState state;
  final ActivityDialController controller;

  @override
  Widget build(BuildContext context) {
    final logs = state.todayLogs;
    final timeFormat = DateFormat('HH:mm');

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    'Nhật ký hôm nay',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF261E1A),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, color: Color(0xFF6E6259)),
              ),
            ],
          ),

          if (state.latestLog != null) ...[
            const SizedBox(height: 4),
            Text(
              'Lần chấm gần nhất: ${state.latestLog!.name} (${timeFormat.format(state.latestLog!.occurredAt)})',
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
                  return _LogItemTile(
                    log: log,
                    timeStr: timeFormat.format(log.occurredAt),
                    onDelete: () async {
                      await controller.deleteLog(log.id);
                      if (context.mounted && state.todayCount <= 1) {
                        Navigator.pop(context);
                      }
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _LogItemTile extends StatelessWidget {
  const _LogItemTile({
    required this.log,
    required this.timeStr,
    required this.onDelete,
  });

  final ActivityLog log;
  final String timeStr;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F4EB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDE4D6)),
      ),
      child: Row(
        children: [
          Text(
            log.emoji,
            style: const TextStyle(fontSize: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2E241F),
                  ),
                ),
                Text(
                  'Lúc $timeStr • Đã lưu thiết bị (DAT-01)',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF8A7E74),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFD34E2F), size: 20),
            tooltip: 'Xóa bản ghi (LOG-04)',
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
