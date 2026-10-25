import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../activity_dial_controller.dart';
import '../../domain/activity_event_type.dart';
import '../widgets/orbital_dial_widget.dart';
import '../widgets/today_logs_sheet.dart';
import '../widgets/today_summary_card.dart';
import '../widgets/user_profile_sheet.dart';

/// Màn hình chính "Chấm — Màn hình chính (Wear OS Dial)"
/// Chuẩn xác 100% theo bản thiết kế mẫu và yêu cầu SRS (LOG-01 → 05, DAT-01).
class ActivityDialPage extends ConsumerWidget {
  const ActivityDialPage({super.key});

  void _showFeedbackToast(BuildContext context, ActivityEventType type) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        backgroundColor: const Color(0xFF2B221D),
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: const Duration(seconds: 2),
        content: Row(
          children: [
            Text(type.emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Đã chấm: ${type.name} (+1 chấm)',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFFF694A),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Đã lưu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openTodayLogsSheet(
    BuildContext context,
    ActivityDialState state,
    ActivityDialController controller,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TodayLogsSheet(
        state: state,
        controller: controller,
      ),
    );
  }

  void _openProfileSheet(BuildContext context, ActivityDialState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => UserProfileSheet(state: state),
    );
  }

  void _openSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFFFFDF9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Cài đặt ứng dụng',
          style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF261E1A)),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• Chế độ: Local-First (DAT-01)'),
            SizedBox(height: 6),
            Text('• Ghi 1-chạm: Bật tức thì (LOG-03)'),
            SizedBox(height: 6),
            Text('• Đồng bộ Server: Tự động khi có mạng (DAT-03)'),
            SizedBox(height: 6),
            Text('• Phiên bản: v1.0.0 (PRM393)'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(activityDialControllerProvider);
    final controller = ref.read(activityDialControllerProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF6F0),
      body: SafeArea(
        child: state.isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFFF694A)),
              )
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- 1. APP HEADER: "Chấm •" + Settings & Avatar ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Tiêu đề Chấm kèm dấu chấm san hô
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            const Text(
                              'Chấm',
                              style: TextStyle(
                                fontSize: 27,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF1F1A17),
                                letterSpacing: -0.6,
                              ),
                            ),
                            const SizedBox(width: 3.5),
                            Container(
                              width: 8.5,
                              height: 8.5,
                              margin: const EdgeInsets.only(bottom: 3),
                              decoration: const BoxDecoration(
                                color: Color(0xFFFF6F52),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),

                        // Action icons góc phải
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => _openSettingsDialog(context),
                              icon: const Icon(
                                Icons.settings_outlined,
                                color: Color(0xFF4A403A),
                                size: 24,
                              ),
                              tooltip: 'Cài đặt',
                            ),
                            const SizedBox(width: 4),
                            InkWell(
                              onTap: () => _openProfileSheet(context, state),
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                width: 34,
                                height: 34,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFA93B24),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.person_rounded,
                                  size: 21,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // --- 2. BANNER CARD: HÔM NAY + "4 chấm" badge ---
                    TodaySummaryCard(
                      todayCount: state.todayCount,
                      onTap: () => _openTodayLogsSheet(context, state, controller),
                    ),

                    const SizedBox(height: 20),

                    // --- 3. RADIAL ORBITAL DIAL (Wear OS Dial) ---
                    OrbitalDialWidget(
                      eventTypes: state.eventTypes,
                      onTapNode: (type) async {
                        await controller.quickLog(type);
                        if (context.mounted) {
                          _showFeedbackToast(context, type);
                        }
                      },
                      onTapCenter: () => _openTodayLogsSheet(context, state, controller),
                    ),
                  ],
                ),
              ),
      ),

      // --- 4. FLOATING ACTION BUTTON (Góc dưới phải: nút tròn đen) ---
      floatingActionButton: FloatingActionButton(
        elevation: 4,
        backgroundColor: const Color(0xFF221C18),
        shape: const CircleBorder(),
        onPressed: () => _openTodayLogsSheet(context, state, controller),
        child: const Icon(
          Icons.auto_awesome_rounded,
          color: Colors.white,
          size: 23,
        ),
      ),
    );
  }
}
