import 'dart:math';
import 'package:flutter/material.dart';

/// Vẽ 3 vòng quỹ đạo đồng tâm nét đứt (Concentric Dashed Orbits)
/// chuẩn xác theo phong cách "Wear OS Dial"
class OrbitalDialPainter extends CustomPainter {
  const OrbitalDialPainter({
    required this.r1,
    required this.r2,
    required this.r3,
    this.orbitColor = const Color(0xFFEADFD3),
    this.haloColor = const Color(0x22FF7A59),
  });

  final double r1;
  final double r2;
  final double r3;
  final Color orbitColor;
  final Color haloColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Vầng hào quang sáng ấm áp quanh nút trung tâm
    final haloPaint = Paint()
      ..color = haloColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawCircle(center, r1 * 0.72, haloPaint);

    final dashPaint = Paint()
      ..color = orbitColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Vẽ 3 vòng tròn nét đứt
    _drawDashedCircle(canvas, center, r1, dashPaint, dashLength: 4.0, gapLength: 4.5);
    _drawDashedCircle(canvas, center, r2, dashPaint, dashLength: 4.5, gapLength: 5.0);
    _drawDashedCircle(canvas, center, r3, dashPaint, dashLength: 5.0, gapLength: 5.5);
  }

  void _drawDashedCircle(
    Canvas canvas,
    Offset center,
    double radius,
    Paint paint, {
    required double dashLength,
    required double gapLength,
  }) {
    final circumference = 2 * pi * radius;
    final totalDashes = (circumference / (dashLength + gapLength)).floor();
    final adjustedDashAngle = (2 * pi * (dashLength / (dashLength + gapLength))) / totalDashes;
    final adjustedGapAngle = (2 * pi * (gapLength / (dashLength + gapLength))) / totalDashes;

    var currentAngle = 0.0;
    for (var i = 0; i < totalDashes; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        currentAngle,
        adjustedDashAngle,
        false,
        paint,
      );
      currentAngle += adjustedDashAngle + adjustedGapAngle;
    }
  }

  @override
  bool shouldRepaint(covariant OrbitalDialPainter oldDelegate) {
    return oldDelegate.r1 != r1 ||
        oldDelegate.r2 != r2 ||
        oldDelegate.r3 != r3 ||
        oldDelegate.orbitColor != orbitColor;
  }
}
