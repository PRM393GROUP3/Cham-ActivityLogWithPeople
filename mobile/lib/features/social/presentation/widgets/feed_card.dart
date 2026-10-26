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
                        text: share.isMine ? 'Bạn' : share.ownerName,
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

                // Thanh reaction: chạm để thả / đổi, chạm lại để gỡ. Bài của mình: chỉ xem số đếm.
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF8F5),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      for (final reaction in Reaction.values) _buildReactionButton(context, reaction),
                    ],
                  ),
                ),
                if (share.isMine) ...[
                  const SizedBox(height: 6),
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: share.reactors.isEmpty ? null : () => _showReactors(context),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        share.reactors.isEmpty
                            ? 'Chưa có ai thả cảm xúc'
                            : '${share.reactors.length} người đã thả cảm xúc · Xem',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: share.reactors.isEmpty ? FontWeight.w400 : FontWeight.w700,
                          color: share.reactors.isEmpty ? const Color(0xFF8A7E74) : const Color(0xFFB53216),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Ai đã thả cảm xúc gì vào bài của mình.
  void _showReactors(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFFFFFDF9),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
              child: Text(
                'Cảm xúc cho ${share.emoji} ${share.name}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
                children: [
                  for (final r in share.reactors)
                    ListTile(
                      leading: UserAvatar(name: r.displayName, emoji: r.avatarEmoji, radius: 20),
                      title: Text(r.displayName, style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text(VnTime.relative(r.reactedAt)),
                      trailing: Text(r.emoji, style: const TextStyle(fontSize: 24)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReactionButton(BuildContext context, Reaction reaction) {
    final isSelected = share.myReaction == reaction.emoji;
    final count = share.reactionCounts[reaction.emoji] ?? 0;

    return Tooltip(
      message: reaction.label,
      child: GestureDetector(
        // Không tự thả cảm xúc cho bài của mình (server cũng chặn): chạm thì mở danh sách người thả.
        onTap: () => share.isMine
            ? (share.reactors.isEmpty ? null : _showReactors(context))
            : onReactionTap(reaction.emoji),
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
