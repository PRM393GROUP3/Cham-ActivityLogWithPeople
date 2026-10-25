import 'package:flutter/material.dart';

import '../../domain/feed_item.dart';

class FeedCard extends StatelessWidget {
  const FeedCard({
    super.key,
    required this.item,
    required this.onReactionTap,
  });

  final FeedItem item;
  final ValueChanged<String> onReactionTap;

  static const List<String> availableReactions = ['❤️', '👍', '😊', '😢', '😆'];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3EFEA),
        borderRadius: BorderRadius.circular(24.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Column: User Avatar + Overlapping Activity Badge
          SizedBox(
            width: 56,
            height: 56,
            child: Stack(
              children: [
                // Avatar
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(
                    child: Image.network(
                      item.avatarUrl,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: const Color(0xFFE6DFD5),
                        alignment: Alignment.center,
                        child: Text(
                          item.userName.isNotEmpty ? item.userName[0] : '?',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E1B18),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Activity Badge overlapping bottom-right corner
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        item.badgeIcon,
                        size: 14,
                        color: item.badgeColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 14),

          // Right Column: Activity details + Reaction Pill Bar
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Activity Line: Bold userName + actionText
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: item.userName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E1B18),
                        ),
                      ),
                      const TextSpan(text: ' '),
                      TextSpan(
                        text: item.actionText,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: item.isHighlightedAction
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: item.isHighlightedAction
                              ? const Color(0xFF8C2D19)
                              : const Color(0xFF1E1B18),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 4),

                // Timestamp: Clock icon + timestamp text
                Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      size: 16,
                      color: Color(0xFF6E655F),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      item.timestamp,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6E655F),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Interactive Reaction Pill Bar
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF8F5),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      for (final emoji in availableReactions)
                        _buildEmojiButton(emoji),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmojiButton(String emoji) {
    final isSelected = item.selectedReaction == emoji;

    return GestureDetector(
      onTap: () => onReactionTap(emoji),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(6.0),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFADCD9) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Text(
          emoji,
          style: TextStyle(
            fontSize: isSelected ? 22 : 18,
            height: 1.1,
          ),
        ),
      ),
    );
  }
}
