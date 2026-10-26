import 'package:flutter/material.dart';

import '../../../../core/time/vn_time.dart';
import '../../../account/presentation/widgets/user_avatar.dart';
import '../../domain/feed_share.dart';
import '../../domain/reaction.dart';

/// Thẻ một bản ghi Public của bạn bè, kèm thanh 7 reaction (SOC-05).
class FeedCard extends StatelessWidget {
  const FeedCard({
    super.key,
    required this.share,
    required this.onReactionTap,
  });

  final FeedShare share;
  final ValueChanged<String> onReactionTap;

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
          // Left Column: avatar (chữ cái đầu) + emoji hoạt động
          SizedBox(
            width: 56,
            height: 56,
            child: Stack(
              children: [
                UserAvatar(name: share.ownerName, emoji: share.ownerAvatarEmoji, radius: 28),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 26,
                    height: 26,
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
                    alignment: Alignment.center,
                    child: Text(share.emoji, style: const TextStyle(fontSize: 14)),
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
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: share.ownerName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E1B18),
                        ),
                      ),
                      TextSpan(
                        text: ' đã chấm ${share.emoji} ${share.name}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF1E1B18),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 4),

                Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      size: 16,
                      color: Color(0xFF6E655F),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      VnTime.relative(share.occurredAt),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6E655F),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Thanh reaction: chạm để thả / đổi, chạm lại để gỡ
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF8F5),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      for (final reaction in Reaction.values) _buildReactionButton(reaction),
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

  Widget _buildReactionButton(Reaction reaction) {
    final isSelected = share.myReaction == reaction.emoji;
    final count = share.reactionCounts[reaction.emoji] ?? 0;

    return Tooltip(
      message: reaction.label,
      child: GestureDetector(
        onTap: () => onReactionTap(reaction.emoji),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFADCD9) : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                reaction.emoji,
                style: TextStyle(fontSize: isSelected ? 20 : 17, height: 1.1),
              ),
              if (count > 0)
                Text(
                  '$count',
                  style: const TextStyle(fontSize: 10, color: Color(0xFF6E655F), fontWeight: FontWeight.w600),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
