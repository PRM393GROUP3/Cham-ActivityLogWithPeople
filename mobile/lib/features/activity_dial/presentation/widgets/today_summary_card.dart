import 'package:flutter/material.dart';

import '../../../../core/time/vn_time.dart';

/// Thẻ thông tin "Hôm nay" hiển thị thứ ngày và số lượng "chấm"
/// Bấm vào để xem lịch sử chi tiết trong ngày (HIS-01)
class TodaySummaryCard extends StatelessWidget {
  const TodaySummaryCard({
    super.key,
    required this.todayCount,
    required this.onTap,
  });

  final int todayCount;
  final VoidCallback onTap;

  String _formatDayTitle(DateTime now) {
    // Thứ trong tuần kèm câu chúc thong thả sinh động
    const weekdays = [
      'Thứ Hai tươi mới',
      'Thứ Ba tích cực',
      'Thứ Tư năng động',
      'Thứ Năm thong thả',
      'Thứ Sáu hứng khởi',
      'Thứ Bảy thảnh thơi',
      'Chủ Nhật an yên',
    ];
    return weekdays[now.weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    final now = VnTime.now();
    final dayMonthStr = 'HÔM NAY, ${now.day} THÁNG ${now.month}';
    final weekdayStr = _formatDayTitle(now);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F0E6),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: const Color(0xFFEBE0D2),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Cột bên trái: Ngày tháng & Thứ
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    dayMonthStr,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: Color(0xFF8C8074),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          weekdayStr,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF241D19),
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFF66BB6A),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Cột bên phải: Badge số chấm + mũi tên
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Badge số chấm
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF6EE),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFE8DFD3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF694A),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5.5),
                      Text(
                        '$todayCount chấm',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF322722),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 6),

                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 13,
                  color: Color(0xFF9E9287),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
