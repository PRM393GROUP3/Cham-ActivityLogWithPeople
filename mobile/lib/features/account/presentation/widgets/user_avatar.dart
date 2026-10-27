import 'package:flutter/material.dart';

/// Avatar của một người dùng: emoji họ chọn, hoặc chữ cái đầu của tên khi chưa chọn.
class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, required this.name, this.emoji, this.radius = 22, this.backgroundColor});

  final String name;
  final String? emoji;
  final double radius;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final hasEmoji = emoji != null && emoji!.isNotEmpty;
    return Container(
      width: radius * 2,
      height: radius * 2,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: backgroundColor ?? (hasEmoji ? const Color(0xFFFFF4EC) : const Color(0xFFE6DFD5)),
        shape: BoxShape.circle,
      ),
      child: Text(
        hasEmoji ? emoji! : (name.isNotEmpty ? name.characters.first.toUpperCase() : '?'),
        style: hasEmoji
            ? TextStyle(fontSize: radius * 1.05, height: 1.1)
            : TextStyle(fontSize: radius * 0.8, fontWeight: FontWeight.bold, color: const Color(0xFF1E1B18)),
      ),
    );
  }
}
