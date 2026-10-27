import 'package:flutter/material.dart';
import '../../domain/widget_config.dart';

class WidgetMediumPreview extends StatefulWidget {
  final int streakDays;

  const WidgetMediumPreview({
    super.key,
    this.streakDays = 12,
  });

  @override
  State<WidgetMediumPreview> createState() => _WidgetMediumPreviewState();
}

class _WidgetMediumPreviewState extends State<WidgetMediumPreview>
    with SingleTickerProviderStateMixin {
  late List<QuickLogItem> _items;
  int? _animatingIndex;
  late final AnimationController _glowController;
  late final Animation<double> _glowCurve;

  static const _glowAccents = <Color>[
    Color(0xFFFF5722),
    Color(0xFF2ECC71),
    Color(0xFF8E44AD),
    Color(0xFF2980B9),
  ];

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 680),
    );
    _glowCurve = CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeOutCubic,
    );
    _glowController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _animatingIndex = null);
      }
    });

    _items = [
      const QuickLogItem(
        id: 'coffee',
        title: 'Cà phê',
        icon: Icons.coffee_rounded,
        backgroundColor: Color(0xFFE85835),
        iconColor: Colors.white,
        dotColor: Color(0xFFE85835),
        isCompleted: true,
        todayCount: 2,
      ),
      const QuickLogItem(
        id: 'running',
        title: 'Chạy bộ',
        icon: Icons.directions_run_rounded,
        backgroundColor: Color(0xFFC3EBC7),
        iconColor: Color(0xFF236928),
        dotColor: Color(0xFF43A047),
        isCompleted: true,
        todayCount: 1,
      ),
      const QuickLogItem(
        id: 'reading',
        title: 'Đọc sá...',
        icon: Icons.menu_book_rounded,
        backgroundColor: Color(0xFFD3C8E8),
        iconColor: Color(0xFF533F7B),
        dotColor: Color(0xFF7E57C2),
        isCompleted: true,
        todayCount: 1,
      ),
      const QuickLogItem(
        id: 'meditation',
        title: 'Thiền đ...',
        icon: Icons.self_improvement_rounded,
        backgroundColor: Color(0xFFE5DDD5),
        iconColor: Color(0xFF5D534B),
        dotColor: Color(0xFFD6CFC7),
        isCompleted: false,
        todayCount: 0,
      ),
    ];
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  void _toggleItem(int index) {
    setState(() {
      final current = _items[index];
      final nextCount = current.todayCount + 1;
      _animatingIndex = index;
      _items[index] = current.copyWith(
        isCompleted: true,
        todayCount: nextCount,
        dotColor: current.id == 'meditation'
            ? const Color(0xFF8D6E63)
            : current.backgroundColor,
      );
    });
    _glowController.forward(from: 0.0);

    final item = _items[index];
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Đã ghi nhận "${item.title}" (${item.todayCount} chấm hôm nay)!',
            ),
          ],
        ),
        duration: const Duration(milliseconds: 1200),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF2B2523),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  int get _completedCount => _items.where((i) => i.isCompleted).length;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFF7F3EE),
            const Color(0xFFEFE8DE).withValues(alpha: 0.9),
            const Color(0xFFEAE2D7),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // The 4x2 Medium Widget Card
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 340),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Red Dot + "HÔM NAY"
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE04826),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'HÔM NAY',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                            color: Color(0xFF423B37),
                          ),
                        ),
                      ],
                    ),

                    // Progress Pill Badge "✓ 3/4"
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCF3E4),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check_rounded,
                            size: 13,
                            color: Color(0xFF2E7D32),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '$_completedCount/${_items.length}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // 4 Action Buttons Row
                AnimatedBuilder(
                  animation: _glowCurve,
                  builder: (context, _) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(_items.length, (index) {
                        final item = _items[index];
                        return _buildActionButton(
                          index: index,
                          item: item,
                          isAnimating: _animatingIndex == index,
                          progress: _glowCurve.value,
                          onTap: () => _toggleItem(index),
                        );
                      }),
                    );
                  },
                ),

                const SizedBox(height: 12),

                // Bottom Indicator Bar: Dots + Streak
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Colored Status Dots
                    Row(
                      children: _items.map((item) {
                        return Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(right: 5),
                          decoration: BoxDecoration(
                            color: item.dotColor,
                            shape: BoxShape.circle,
                          ),
                        );
                      }).toList(),
                    ),

                    // Lightning Streak
                    Row(
                      children: [
                        const Icon(
                          Icons.bolt_rounded,
                          size: 15,
                          color: Color(0xFF6E6662),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          'Chuỗi ${widget.streakDays} ngày',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6E6662),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Subtitle with Touch Hand Icon
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(
                Icons.touch_app_outlined,
                size: 16,
                color: Color(0xFF6E6662),
              ),
              SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Chạm trực tiếp trên màn hình chính để ghi nhận',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6E6662),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required int index,
    required QuickLogItem item,
    required bool isAnimating,
    required double progress,
    required VoidCallback onTap,
  }) {
    final hasLogs = item.todayCount > 0;
    final glowColor = _glowAccents[index % _glowAccents.length];
    // Bell-shaped intensity curve: peaks quickly then softly fades out
    final glowIntensity = isAnimating
        ? (progress < 0.35 ? progress / 0.35 : (1.0 - progress) / 0.65).clamp(0.0, 1.0)
        : 0.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Today count pill above each habit icon
        Container(
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
          decoration: BoxDecoration(
            color: hasLogs ? const Color(0xFFFFF0E6) : const Color(0xFFF4EFEA),
            borderRadius: BorderRadius.circular(8),
            border: hasLogs
                ? Border.all(color: const Color(0xFFF5C7B3), width: 0.8)
                : null,
          ),
          child: Text(
            '${item.todayCount} chấm',
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: hasLogs ? const Color(0xFFB53216) : const Color(0xFF7D726A),
            ),
          ),
        ),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            splashColor: Colors.black.withValues(alpha: 0.12),
            child: Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: item.backgroundColor,
                borderRadius: BorderRadius.circular(16),
                border: glowIntensity > 0.05
                    ? Border.all(
                        color: Color.lerp(
                          const Color(0xFFFF9E44),
                          glowColor,
                          0.5,
                        )!.withValues(alpha: (0.4 + 0.6 * glowIntensity).clamp(0.0, 1.0)),
                        width: 1.5 + 1.5 * glowIntensity,
                      )
                    : item.isCompleted
                        ? Border.all(color: Colors.black.withValues(alpha: 0.08), width: 1.2)
                        : null,
                boxShadow: [
                  if (glowIntensity > 0.02) ...[
                    // Diffused backlight radiating from underneath the icon
                    BoxShadow(
                      color: glowColor.withValues(alpha: 0.55 * glowIntensity),
                      blurRadius: 18 * glowIntensity + 6,
                      spreadRadius: 4 * glowIntensity,
                      offset: const Offset(0, 4),
                    ),
                    // Warm inner aura around the border
                    BoxShadow(
                      color: const Color(0xFFFF9E44).withValues(alpha: 0.45 * glowIntensity),
                      blurRadius: 10 * glowIntensity + 2,
                      spreadRadius: 1.5 * glowIntensity,
                      offset: Offset.zero,
                    ),
                  ],
                  BoxShadow(
                    color: item.backgroundColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                item.icon,
                size: 26,
                color: item.iconColor,
              ),
            ),
          ),
        ),
        const SizedBox(height: 5),
        SizedBox(
          width: 58,
          child: Text(
            item.title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2C2523),
            ),
          ),
        ),
      ],
    );
  }
}
