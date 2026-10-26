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
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _scaleAnimation;

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
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    _animController.forward().then((_) {
      _animController.reverse();
    });
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
            // Vòng tròn chứa icon màu pastel
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
