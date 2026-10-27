import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/time/vn_time.dart';
import '../../domain/activity_log.dart';
import '../activity_dial_controller.dart';
import '../pages/note_paper_page.dart';

/// Một bản ghi trong lịch sử: giờ, trạng thái lưu / gửi, dòng đầu ghi chú, nút ghi chú,
/// công tắc Riêng tư / Công khai và nút xoá (HIS-01, HIS-02, NOTE-01, SOC-03, SOC-04).
/// Dùng chung cho sheet "Nhật ký hôm nay" và trang Lịch sử & thống kê.
class LogTile extends ConsumerWidget {
  const LogTile({super.key, required this.log, this.showDate = false});

  final ActivityLog log;

  /// Hiện cả ngày (dd/MM) cạnh giờ, dùng khi danh sách trải nhiều ngày.
  final bool showDate;

  /// Trạng thái lưu local luôn hoàn tất trước; trạng thái gửi hiển thị riêng (NFR-03).
  String get _statusText {
    final at = showDate
        ? DateFormat('HH:mm dd/MM').format(VnTime.of(log.occurredAt))
        : VnTime.hm(log.occurredAt);
    final time = 'Lúc $at • Đã lưu trên máy';
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
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(activityDialControllerProvider.notifier);
    void onToggleVisibility() => controller.setVisibility(
          log.id,
          log.isPublic ? ShareVisibility.private : ShareVisibility.public,
        );
    void onDelete() => controller.deleteLog(log.id);
    void onOpenNote() => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => NotePaperPage(logId: log.id)),
        );
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
                if (log.hasNote)
                  Text(
                    '📝 ${log.note!.split('\n').first}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Color(0xFF5E5148),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(
              log.hasNote
                  ? Icons.sticky_note_2_rounded
                  : Icons.sticky_note_2_outlined,
              color: const Color(0xFFB8862E),
              size: 20,
            ),
            tooltip: log.hasNote ? 'Xem / sửa ghi chú' : 'Viết ghi chú',
            onPressed: onOpenNote,
          ),
          _VisibilityChip(isPublic: log.isPublic, onTap: onToggleVisibility),
          IconButton(
            visualDensity: VisualDensity.compact,
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
