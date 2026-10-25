import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Nút tròn nổi bật "+ CHẤM" ở chính giữa tâm các vòng quỹ đạo
class CenterChamHub extends StatefulWidget {
  const CenterChamHub({
    super.key,
    required this.onTap,
    this.diameter = 86.0,
  });

  final VoidCallback onTap;
  final double diameter;

  @override
  State<CenterChamHub> createState() => _CenterChamHubState();
}

class _CenterChamHubState extends State<CenterChamHub>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 160),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.90).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.mediumImpact();
    _controller.forward().then((_) => _controller.reverse());
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTap: _handleTap,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Vòng hào quang sáng ngoài (Soft glow ring)
            Container(
              width: widget.diameter + 24,
              height: widget.diameter + 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFF7A59).withValues(alpha: 0.16),
              ),
            ),
            // Nút chính màu san hô rực rỡ
            Container(
              width: widget.diameter,
              height: widget.diameter,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFF8A6B),
                    Color(0xFFFF694A),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF694A).withValues(alpha: 0.38),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                  SizedBox(height: 1),
                  Text(
                    'CHẤM',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
