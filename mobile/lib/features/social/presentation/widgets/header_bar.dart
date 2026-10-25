import 'package:flutter/material.dart';

class HeaderBar extends StatelessWidget {
  const HeaderBar({
    super.key,
    this.onBackPressed,
    this.onSettingsPressed,
    this.onProfilePressed,
  });

  final VoidCallback? onBackPressed;
  final VoidCallback? onSettingsPressed;
  final VoidCallback? onProfilePressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Optional Back button + "Chấm" + Coral Dot
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (onBackPressed != null) ...[
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Color(0xFF1E1B18)),
                  onPressed: onBackPressed,
                  tooltip: 'Trang chủ',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
              ],
              const Text(
                'Chấm',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1E1B18),
                  letterSpacing: -0.5,
                  fontFamily: 'sans-serif',
                ),
              ),
              const SizedBox(width: 4),
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Color(0xFFFF6B4A),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),

          // Right: Settings gear + Profile button
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                color: const Color(0xFF5C4033),
                iconSize: 24,
                onPressed: onSettingsPressed ?? () {},
                tooltip: 'Cài đặt Widget',
              ),
              const SizedBox(width: 6),
              Material(
                color: const Color(0xFF9E2A1C),
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: onProfilePressed ?? () {},
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
