import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/time/vn_time.dart';
import '../activity_dial_controller.dart';
import '../../../account/presentation/account_controller.dart';
import '../../../account/presentation/widgets/user_avatar.dart';
import '../../domain/activity_event_type.dart';
import '../widgets/add_activity_dialog.dart';
import '../widgets/orbital_dial_widget.dart';
import '../widgets/today_logs_sheet.dart';
import '../widgets/today_summary_card.dart';
import '../widgets/user_profile_sheet.dart';

/// Màn hình chính "Chấm — Màn hình chính (Wear OS Dial)"
/// Chuẩn xác 100% theo bản thiết kế mẫu và yêu cầu SRS (LOG-01 → 05, DAT-01).
class ActivityDialPage extends ConsumerWidget {
  const ActivityDialPage({
    super.key,
    this.onNavigateToFeed,
    this.onNavigateToAnalytics,
    this.onNavigateToHistory,
  });

  /// Có khi nằm trong shell vuốt: hiện gợi ý vuốt tới màn tương ứng.
  final VoidCallback? onNavigateToFeed;
  final VoidCallback? onNavigateToAnalytics;
  final VoidCallback? onNavigateToHistory;

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
                'Đã chấm ${type.name} lúc ${VnTime.hm(DateTime.now())}',
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

  void _openTodayLogsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TodayLogsSheet(onViewHistory: onNavigateToHistory),
    );
  }

  void _openProfileSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const UserProfileSheet(),
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
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF261E1A),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Phiên bản: v1.0.0 (PRM393)'),
            const SizedBox(height: 14),
            const Divider(color: Color(0xFFE5DDD5)),
            const SizedBox(height: 6),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2ECE4),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.add_reaction_outlined,
                  color: Color(0xFFB53216),
                ),
              ),
              title: const Text(
                'Loại sự kiện',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
              ),
              subtitle: const Text(
                'Thêm, sửa, xoá, sắp xếp icon trên trang chủ',
                style: TextStyle(fontSize: 11.5, color: Color(0xFF7E7268)),
              ),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.pushNamed(context, '/event-types');
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2ECE4),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.widgets_outlined,
                  color: Color(0xFFB53216),
                ),
              ),
              title: const Text(
                'Cài đặt Widget (2×2, 4×2)',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
              ),
              subtitle: const Text(
                'Tùy chỉnh widget trên màn hình chính',
                style: TextStyle(fontSize: 11.5, color: Color(0xFF7E7268)),
              ),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.pushNamed(context, '/widgets');
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Đóng',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(activityDialControllerProvider);
    final account = ref.watch(accountControllerProvider).value;
    final controller = ref.read(activityDialControllerProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF6F0),
      body: SafeArea(
        child: state.isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFFF694A)),
              )
            : Stack(
                children: [
                  // Không cuộn: kéo dọc trên Trang chủ là để mở màn Bạn bè.
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      18,
                      12,
                      18,
                      onNavigateToFeed == null ? 20 : 52,
                    ),
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

                            // Action icons góc phải. Phân tích / Lịch sử / Bạn bè mở bằng vuốt.
                            Row(
                              children: [
                                IconButton(
                                  onPressed: () => _openSettingsDialog(context),
                                  icon: const Icon(
                                    Icons.settings_outlined,
                                    color: Color(0xFF4A403A),
                                    size: 23,
                                  ),
                                  tooltip: 'Cài đặt',
                                ),
                                const SizedBox(width: 4),
                                InkWell(
                                  onTap: () => _openProfileSheet(context),
                                  borderRadius: BorderRadius.circular(20),
                                  child: account?.avatarEmoji != null
                                      ? Tooltip(
                                          message: 'Hồ sơ',
                                          child: UserAvatar(
                                            name: account!.displayName,
                                            emoji: account.avatarEmoji,
                                            radius: 17,
                                          ),
                                        )
                                      : Container(
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
                          onTap: () => _openTodayLogsSheet(context),
                        ),

                        const SizedBox(height: 20),

                        // --- 3. RADIAL ORBITAL DIAL (Wear OS Dial) ---
                        // Thu nhỏ vừa phần còn lại của màn hình thay vì cuộn.
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) => FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.topCenter,
                              child: SizedBox(
                                width: constraints.maxWidth,
                                child: OrbitalDialWidget(
                                  eventTypes: state.dialTypes,
                                  onTapNode: (type) async {
                                    await controller.quickLog(type);
                                    if (context.mounted) {
                                      _showFeedbackToast(context, type);
                                    }
                                  },
                                  onTapCenter: () =>
                                      showAddActivityDialog(context),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // --- Gợi ý vuốt: Phân tích (trái), Lịch sử (phải), Bạn bè (dưới) ---
                  if (onNavigateToAnalytics != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _EdgeHint(
                        icon: Icons.chevron_left_rounded,
                        label: 'Phân tích',
                        onTap: onNavigateToAnalytics!,
                      ),
                    ),
                  if (onNavigateToHistory != null)
                    Align(
                      alignment: Alignment.centerRight,
                      child: _EdgeHint(
                        icon: Icons.chevron_right_rounded,
                        label: 'Lịch sử',
                        onTap: onNavigateToHistory!,
                      ),
                    ),
                  if (onNavigateToFeed != null)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: _FeedPeekBar(onTap: onNavigateToFeed!),
                    ),
                ],
              ),
      ),
    );
  }
}

/// Mũi tên mờ ở mép màn hình, gợi ý vuốt ngang; bấm cũng chuyển màn.
class _EdgeHint extends StatelessWidget {
  const _EdgeHint({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 22,
          height: 72,
          child: Icon(icon, size: 20, color: const Color(0x55786A60)),
        ),
      ),
    );
  }
}

/// Thanh mờ ở đáy Trang chủ: mũi tên nhún nhẹ vài lần gợi ý vuốt lên để xem Bạn bè.
class _FeedPeekBar extends StatefulWidget {
  const _FeedPeekBar({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_FeedPeekBar> createState() => _FeedPeekBarState();
}

class _FeedPeekBarState extends State<_FeedPeekBar>
    with SingleTickerProviderStateMixin {
  /// Nhún 3 lần rồi đứng yên, để không gây rối mắt.
  static const _bounces = 3;
  int _done = 0;

  late final AnimationController _bob =
      AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 700),
      )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _bob.reverse();
        } else if (status == AnimationStatus.dismissed && ++_done < _bounces) {
          _bob.forward();
        }
      });

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _bob.forward();
    });
  }

  @override
  void dispose() {
    _bob.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Bạn bè',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        // Dải mờ dần bằng gradient thay cho BackdropFilter: blur phải tính lại mỗi khung hình
        // lúc vuốt chuyển màn, làm vuốt bị khựng; phía sau thanh vốn chỉ là nền trơn.
        child: Container(
          height: 56,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x00FAF6F0), Color(0xCCF6EFE5), Color(0xFFF3EBDF)],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _bob,
                builder: (context, child) => Transform.translate(
                  offset: Offset(
                    0,
                    -4 * Curves.easeInOut.transform(_bob.value),
                  ),
                  child: child,
                ),
                child: const Icon(
                  Icons.keyboard_arrow_up_rounded,
                  size: 22,
                  color: Color(0xFF9E9287),
                ),
              ),
              const Text(
                'Bạn bè',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF9E9287),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
