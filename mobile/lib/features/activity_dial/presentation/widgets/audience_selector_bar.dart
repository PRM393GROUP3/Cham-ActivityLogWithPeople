import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/activity_log.dart';

/// Thanh chọn đối tượng chia sẻ theo phong cách Locket Widget (SOC-03):
/// Cho phép người dùng chuyển nhanh giữa:
/// - [ShareVisibility.public]: "👥 Bạn bè" (Tự động chia sẻ lên Feed)
/// - [ShareVisibility.private]: "🔒 Chỉ mình tôi" (Lưu riêng tư trên máy)
/// Lựa chọn được tự động lưu lại cho các lần chấm tiếp theo (Sticky preference).
class AudienceSelectorBar extends StatelessWidget {
  const AudienceSelectorBar({
    super.key,
    required this.selectedMode,
    required this.onChanged,
  });

  final ShareVisibility selectedMode;
  final ValueChanged<ShareVisibility> onChanged;

  bool get _isPublic => selectedMode == ShareVisibility.public;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFEDE4D6),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2D6C5)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tabWidth = (constraints.maxWidth - 2) / 2;
          return Stack(
            children: [
              // Sliding Animated Pill Indicator
              AnimatedAlign(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOutCubic,
                alignment: _isPublic ? Alignment.centerLeft : Alignment.centerRight,
                child: Container(
                  width: tabWidth,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: _isPublic
                        ? const Color(0xFFB53216) // Coral Red ấm áp của Chăm
                        : const Color(0xFF2E241F), // Espresso sẫm riêng tư
                    borderRadius: BorderRadius.circular(19),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1E000000),
                        blurRadius: 4,
                        offset: Offset(0, 1.5),
                      ),
                    ],
                  ),
                ),
              ),

              // Hai nút bấm chọn đối tượng
              Row(
                children: [
                  Expanded(
                    child: _AudienceTabItem(
                      icon: Icons.people_alt_rounded,
                      label: 'Bạn bè',
                      isSelected: _isPublic,
                      selectedColor: Colors.white,
                      unselectedColor: const Color(0xFF73665C),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        onChanged(ShareVisibility.public);
                      },
                    ),
                  ),
                  Expanded(
                    child: _AudienceTabItem(
                      icon: Icons.lock_outline_rounded,
                      label: 'Chỉ mình tôi',
                      isSelected: !_isPublic,
                      selectedColor: Colors.white,
                      unselectedColor: const Color(0xFF73665C),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        onChanged(ShareVisibility.private);
                      },
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AudienceTabItem extends StatelessWidget {
  const _AudienceTabItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.selectedColor,
    required this.unselectedColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final Color selectedColor;
  final Color unselectedColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Center(
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 180),
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? selectedColor : unselectedColor,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected ? selectedColor : unselectedColor,
              ),
              const SizedBox(width: 5),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }
}

