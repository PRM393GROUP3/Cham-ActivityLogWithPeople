import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/activity_event_type.dart';

/// Một nút tròn trên quỹ đạo Dial (Wear OS node)
/// Bao gồm biểu tượng trong vòng tròn màu pastel và nhãn tên bên dưới
class RadialDialNode extends StatefulWidget {
  const RadialDialNode({
    super.key,
    required this.type,
    required this.onTap,
    this.iconSize = 19.0,
    this.circleRadius = 19.0,
  });

  final ActivityEventType type;
  final VoidCallback onTap;
  final double iconSize;
  final double circleRadius;

  @override
  State<RadialDialNode> createState() => _RadialDialNodeState();
}

class _RadialDialNodeState extends State<RadialDialNode>
    with TickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _scaleAnimation;

  /// Hiệu ứng sau mỗi lần chấm: vòng màu lan ra và "+1" bay lên rồi mờ dần.
  late final AnimationController _burstController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.82).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
    _burstController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
  }

  @override
  void dispose() {
    _burstController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    _animController.forward().then((_) {
      _animController.reverse();
    });
    _burstController.forward(from: 0);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _handleTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Vòng tròn chứa icon màu pastel, cùng hiệu ứng sau mỗi lần chấm
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                _BurstRing(
                  animation: _burstController,
                  size: widget.circleRadius * 2,
                  color: widget.type.accentColor,
                ),
            Container(
              width: widget.circleRadius * 2,
              height: widget.circleRadius * 2,
              decoration: BoxDecoration(
                color: widget.type.bgColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.type.accentColor.withValues(alpha: 0.35),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.type.accentColor.withValues(alpha: 0.12),
                    blurRadius: 4,
                    offset: const Offset(0, 1.5),
                  ),
                ],
              ),
              child: Center(
                child: widget.type.icon != null
                    ? Icon(
                        widget.type.icon,
                        size: widget.iconSize,
                        color: widget.type.accentColor,
                      )
                    : Text(
                        widget.type.emoji,
                        style: TextStyle(fontSize: widget.iconSize),
                      ),
              ),
            ),
                _PlusOne(
                  animation: _burstController,
                  color: widget.type.accentColor,
                  lift: widget.circleRadius * 1.9,
                ),
              ],
            ),
            const SizedBox(height: 2.5),
            // Nhãn chữ bên dưới
            SizedBox(
              width: 58,
              child: Text(
                widget.type.name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10.0,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                  color: Color(0xFF3B322D),
                  height: 1.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Vòng màu lan rộng gấp 2,4 lần nút rồi mờ đi.
class _BurstRing extends AnimatedWidget {
  const _BurstRing({
    required Animation<double> animation,
    required this.size,
    required this.color,
  }) : super(listenable: animation);

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final t = (listenable as Animation<double>).value;
    if (t == 0 || t == 1) return const SizedBox.shrink();
    return IgnorePointer(
      child: Transform.scale(
        scale: 1 + 1.4 * Curves.easeOutCubic.transform(t),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.18 * (1 - t)),
            border: Border.all(color: color.withValues(alpha: 0.7 * (1 - t)), width: 2),
          ),
        ),
      ),
    );
  }
}

/// "+1" bay lên phía trên nút rồi mờ dần.
class _PlusOne extends AnimatedWidget {
  const _PlusOne({
    required Animation<double> animation,
    required this.color,
    required this.lift,
  }) : super(listenable: animation);

  final Color color;
  final double lift;

  @override
  Widget build(BuildContext context) {
    final t = (listenable as Animation<double>).value;
    if (t == 0 || t == 1) return const SizedBox.shrink();
    return Positioned(
      top: -lift * Curves.easeOutCubic.transform(t),
      child: IgnorePointer(
        child: Opacity(
          opacity: t < 0.5 ? 1 : (1 - t) * 2,
          child: Text(
            '+1',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: color),
          ),
        ),
      ),
    );
  }
}
