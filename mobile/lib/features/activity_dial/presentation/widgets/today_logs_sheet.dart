import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/time/vn_time.dart';
import '../activity_dial_controller.dart';
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
                  return _LogItemTile(
                    log: log,
                    onToggleVisibility: () => controller.setVisibility(
                      log.id,
                      log.isPublic
                          ? ShareVisibility.private
                          : ShareVisibility.public,
                    ),
                    onDelete: () => controller.deleteLog(log.id),
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
    required this.onToggleVisibility,
    required this.onDelete,
  });

  final ActivityLog log;
  final VoidCallback onToggleVisibility;
  final VoidCallback onDelete;

  /// Trạng thái lưu local luôn hoàn tất trước; trạng thái gửi hiển thị riêng (NFR-03).
  String get _statusText {
    final time = 'Lúc ${VnTime.hm(log.occurredAt)} • Đã lưu trên máy';
    return switch ((log.visibility, log.syncStatus)) {
      (ShareVisibility.private, ShareSyncStatus.synced) => time,
      (ShareVisibility.private, ShareSyncStatus.pending) =>
        '$time • Đang thu hồi…',
      (ShareVisibility.private, ShareSyncStatus.failed) =>
        '$time • Chưa thu hồi được, sẽ thử lại',
      (ShareVisibility.public, ShareSyncStatus.synced) =>
        '$time • Bạn bè đã thấy',
      (ShareVisibility.public, ShareSyncStatus.pending) =>
        '$time • Đang chờ gửi…',
      (ShareVisibility.public, ShareSyncStatus.failed) =>
        '$time • Chưa gửi được, sẽ thử lại',
    };
  }

  @override
  Widget build(BuildContext context) {
    final failed = log.syncStatus == ShareSyncStatus.failed;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F4EB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDE4D6)),
      ),
      child: Row(
        children: [
          Text(log.emoji, style: const TextStyle(fontSize: 22)),
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
                  _statusText,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: failed
                        ? const Color(0xFFD34E2F)
                        : const Color(0xFF8A7E74),
                  ),
                ),
              ],
            ),
          ),
          _VisibilityChip(isPublic: log.isPublic, onTap: onToggleVisibility),
          IconButton(
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: Color(0xFFD34E2F),
              size: 20,
            ),
            tooltip: 'Xóa bản ghi',
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

/// Công tắc Riêng tư ⇄ Công khai của một bản ghi.
class _VisibilityChip extends StatelessWidget {
  const _VisibilityChip({required this.isPublic, required this.onTap});

  final bool isPublic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: isPublic
          ? 'Chuyển về Riêng tư (thu hồi)'
          : 'Chia sẻ Công khai cho bạn bè',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isPublic ? const Color(0xFFFDEEE8) : const Color(0xFFEFE8DE),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isPublic ? Icons.public_rounded : Icons.lock_outline_rounded,
                size: 14,
                color: isPublic
                    ? const Color(0xFFB53216)
                    : const Color(0xFF6E6259),
              ),
              const SizedBox(width: 4),
              Text(
                isPublic ? 'Công khai' : 'Riêng tư',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isPublic
                      ? const Color(0xFFB53216)
                      : const Color(0xFF6E6259),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
