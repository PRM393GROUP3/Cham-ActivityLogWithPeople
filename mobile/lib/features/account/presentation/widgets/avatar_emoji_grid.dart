import 'package:flutter/material.dart';

import '../../domain/avatar.dart';

/// Lưới emoji gợi ý để chọn làm avatar; ô đang chọn có viền.
class AvatarEmojiGrid extends StatelessWidget {
  const AvatarEmojiGrid({super.key, required this.selected, required this.onPick});

  final String? selected;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    return GridView.extent(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      maxCrossAxisExtent: 52,
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
      children: [
        for (final e in avatarEmojiChoices)
          InkWell(
            key: ValueKey('avatar-$e'),
            borderRadius: BorderRadius.circular(12),
            onTap: () => onPick(e),
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected == e ? const Color(0xFFFDEEE8) : null,
                border: selected == e ? Border.all(color: const Color(0xFFB53216), width: 1.5) : null,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(e, style: const TextStyle(fontSize: 24)),
            ),
          ),
      ],
    );
  }
}
