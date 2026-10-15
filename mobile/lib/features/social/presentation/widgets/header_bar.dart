import 'package:flutter/material.dart';

class HeaderBar extends StatelessWidget {
  const HeaderBar({
    super.key,
    this.onSettingsPressed,
    this.onProfilePressed,
  });

  final VoidCallback? onSettingsPressed;
  final VoidCallback? onProfilePressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: "Chấm" + Coral Dot
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              const Text(
                'Chấm',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1E1B18),
                  letterSpacing: -0.5,
                  fontFamily: 'sans-serif',
                ),
              ),
              const SizedBox(width: 4),
              Container(
                width: 14,
                height: 14,
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
                iconSize: 26,
                onPressed: onSettingsPressed ?? () {},
                tooltip: 'Settings',
              ),
              const SizedBox(width: 8),
              Material(
                color: const Color(0xFF9E2A1C),
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: onProfilePressed ?? () {},
                  child: const Padding(
                    padding: EdgeInsets.all(10.0),
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
