import 'dart:math';
import 'package:flutter/material.dart';

import '../../domain/activity_event_type.dart';
import 'center_cham_hub.dart';
import 'orbital_dial_painter.dart';
import 'radial_dial_node.dart';

/// Vòng xoay các quỹ đạo hoạt động (Radial Orbital Dial)
/// Đặt 19 loại sự kiện trên 3 đường tròn đồng tâm nét đứt quanh nút + CHẤM
class OrbitalDialWidget extends StatelessWidget {
  const OrbitalDialWidget({
    super.key,
    required this.eventTypes,
    required this.onTapNode,
    required this.onTapCenter,
  });

  final List<ActivityEventType> eventTypes;
  final ValueChanged<ActivityEventType> onTapNode;
  final VoidCallback onTapCenter;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Tỷ lệ co giãn mượt mà theo kích thước màn hình thiết bị
        final baseWidth = constraints.maxWidth;
        final scale = (baseWidth / 390.0).clamp(0.82, 1.08);

        final r1 = 67.0 * scale;
        final r2 = 117.0 * scale;
        final r3 = 162.0 * scale;
        final centerDiameter = 82.0 * scale;
        final nodeRadius = 18.5 * scale;
        final nodeIconSize = 19.0 * scale;

        final dialSize = Size(baseWidth, r3 * 2 + 70);
        final center = Offset(dialSize.width / 2, dialSize.height / 2);

        return SizedBox(
          width: dialSize.width,
          height: dialSize.height,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // 1. Vẽ 3 đường tròn đồng tâm nét đứt + Vầng sáng
              CustomPaint(
                size: dialSize,
                painter: OrbitalDialPainter(
                  r1: r1,
                  r2: r2,
                  r3: r3,
                ),
              ),

              // 2. Nút tròn trung tâm "+ CHẤM"
              Center(
                child: CenterChamHub(
                  diameter: centerDiameter,
                  onTap: onTapCenter,
                ),
              ),

              // 3. 19 Nút hoạt động định vị theo toạ độ cực (Radial Polar Coordinates)
              ...eventTypes.map((type) {
                final double r;
                switch (type.orbit) {
                  case 1:
                    r = r1;
                    break;
                  case 2:
                    r = r2;
                    break;
                  case 3:
                  default:
                    r = r3;
                    break;
                }

                // Góc tính bằng Radian
                final rad = type.angleDegree * (pi / 180.0);
                final x = center.dx + r * cos(rad);
                final y = center.dy + r * sin(rad);

                // Chiều rộng ước lượng của Node (Vòng tròn + Nhãn chữ)
                const nodeWidth = 60.0;

                return Positioned(
                  left: x - (nodeWidth / 2),
                  top: y - (nodeRadius),
                  child: RadialDialNode(
                    type: type,
                    circleRadius: nodeRadius,
                    iconSize: nodeIconSize,
                    onTap: () => onTapNode(type),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
