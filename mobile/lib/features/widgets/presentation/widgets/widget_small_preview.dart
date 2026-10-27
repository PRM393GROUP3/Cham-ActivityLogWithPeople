import 'package:flutter/material.dart';

class WidgetSmallPreview extends StatefulWidget {
  final int initialCount;
  final VoidCallback? onLog;

  const WidgetSmallPreview({
    super.key,
    this.initialCount = 4,
    this.onLog,
  });

  @override
  State<WidgetSmallPreview> createState() => _WidgetSmallPreviewState();
}

class _WidgetSmallPreviewState extends State<WidgetSmallPreview>
    with SingleTickerProviderStateMixin {
  late int _count;
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _count = widget.initialCount;
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
      lowerBound: 0.92,
      upperBound: 1.0,
      value: 1.0,
    );
    _scaleAnimation = _animController;
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _handleTap() {
    _animController.reverse().then((_) => _animController.forward());
    setState(() {
      _count++;
    });
    widget.onLog?.call();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text('Đã ghi nhận bản ghi thứ $_count! (One-tap)'),
          ],
        ),
        duration: const Duration(milliseconds: 1200),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF2B2523),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFF4EE),
            Color(0xFFF7FAF4),
            Color(0xFFEDF5EE),
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
          // The 2x2 Widget Card
          Container(
            width: 195,
            height: 195,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: const Color(0xFFE85835).withValues(alpha: 0.06),
                  blurRadius: 24,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top header: Dot + "Chấm log" & Touch icon
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
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
                          'Chấm log',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2C2523),
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                    const Icon(
                      Icons.touch_app_outlined,
                      size: 19,
                      color: Color(0xFF6E6662),
                    ),
                  ],
                ),

                // Center Action Button: Big Coral "+" Circle
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _handleTap,
                      borderRadius: BorderRadius.circular(40),
                      splashColor: Colors.white.withValues(alpha: 0.3),
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFFFF6D4A),
                              Color(0xFFE8522E),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFE8522E).withValues(alpha: 0.38),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.add_rounded,
                          size: 42,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),

                // Bottom row: "4 chấm hôm nay"
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    '$_count chấm hôm nay',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2C2523),
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Subtitle with grid icon
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(
                Icons.grid_view_rounded,
                size: 16,
                color: Color(0xFF6E6662),
              ),
              SizedBox(width: 7),
              Text(
                'Chạm trực tiếp ngoài màn hình chính',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF6E6662),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
