import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Renders a modern dot-matrix styled QR code matching Cham's branding.
class CustomQrView extends StatelessWidget {
  const CustomQrView({
    super.key,
    required this.data,
    this.size = 240,
    this.onTap,
  });

  final String data;
  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F0E9),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: Size(size - 32, size - 32),
              painter: _DotMatrixQrPainter(
                data: data,
                dotColor: const Color(0xFF231F1C),
              ),
            ),
            // Central Cham Touch Badge
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFE85835),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 3.5,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x26000000),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.touch_app_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DotMatrixQrPainter extends CustomPainter {
  _DotMatrixQrPainter({
    required this.data,
    required this.dotColor,
  });

  final String data;
  final Color dotColor;

  static const int _gridSize = 17; // 17x17 grid for clean aesthetic spacing

  @override
  void paint(Canvas canvas, Size size) {
    final double cellSize = size.width / _gridSize;
    final Paint dotPaint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final Paint finderBorderPaint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = cellSize * 0.95
      ..isAntiAlias = true;

    // Draw the 3 corner position markers (finder patterns)
    _drawFinderPattern(canvas, const Offset(0, 0), cellSize, finderBorderPaint, dotPaint);
    _drawFinderPattern(
      canvas,
      Offset((_gridSize - 5) * cellSize, 0),
      cellSize,
      finderBorderPaint,
      dotPaint,
    );
    _drawFinderPattern(
      canvas,
      Offset(0, (_gridSize - 5) * cellSize),
      cellSize,
      finderBorderPaint,
      dotPaint,
    );

    // Deterministic pseudo-random dot pattern seeded by `data`
    final int seed = data.hashCode;
    final math.Random random = math.Random(seed);

    // Matrix representation to prevent clustering around center
    final int centerStart = (_gridSize ~/ 2) - 2;
    final int centerEnd = (_gridSize ~/ 2) + 2;

    for (int r = 0; r < _gridSize; r++) {
      for (int c = 0; c < _gridSize; c++) {
        // Skip corner finder zones (5x5 each)
        final bool inTopLeft = r < 5 && c < 5;
        final bool inTopRight = r < 5 && c >= _gridSize - 5;
        final bool inBottomLeft = r >= _gridSize - 5 && c < 5;

        // Skip center logo zone
        final bool inCenterLogo =
            r >= centerStart && r <= centerEnd && c >= centerStart && c <= centerEnd;

        if (inTopLeft || inTopRight || inBottomLeft || inCenterLogo) {
          continue;
        }

        // Timing/alignment lines or structured dots
        final bool isTimingRow = r == 5 || c == 5;
        final bool isDot = isTimingRow
            ? (r + c) % 2 == 0
            : random.nextDouble() > 0.58;

        if (isDot) {
          final double cx = (c + 0.5) * cellSize;
          final double cy = (r + 0.5) * cellSize;
          final double radius = cellSize * 0.42;
          canvas.drawCircle(Offset(cx, cy), radius, dotPaint);
        }
      }
    }
  }

  void _drawFinderPattern(
    Canvas canvas,
    Offset origin,
    double cellSize,
    Paint borderPaint,
    Paint innerPaint,
  ) {
    const double patternSizeInCells = 5.0;
    final double patternWidth = patternSizeInCells * cellSize;

    // Outer rounded square frame
    final Rect outerRect = Rect.fromLTWH(
      origin.dx + borderPaint.strokeWidth / 2,
      origin.dy + borderPaint.strokeWidth / 2,
      patternWidth - borderPaint.strokeWidth,
      patternWidth - borderPaint.strokeWidth,
    );
    final RRect outerRRect = RRect.fromRectAndRadius(
      outerRect,
      Radius.circular(cellSize * 1.3),
    );
    canvas.drawRRect(outerRRect, borderPaint);

    // Inner rounded square dot
    final double innerMargin = cellSize * 1.6;
    final Rect innerRect = Rect.fromLTWH(
      origin.dx + innerMargin,
      origin.dy + innerMargin,
      patternWidth - (innerMargin * 2),
      patternWidth - (innerMargin * 2),
    );
    final RRect innerRRect = RRect.fromRectAndRadius(
      innerRect,
      Radius.circular(cellSize * 0.7),
    );
    canvas.drawRRect(innerRRect, innerPaint);
  }

  @override
  bool shouldRepaint(covariant _DotMatrixQrPainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.dotColor != dotColor;
  }
}

