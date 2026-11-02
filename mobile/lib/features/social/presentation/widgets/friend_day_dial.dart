import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../core/time/vn_time.dart';
import '../../../account/presentation/widgets/user_avatar.dart';
import '../../../activity_dial/domain/dial_layout.dart';
import '../../../activity_dial/presentation/widgets/orbital_dial_painter.dart';
import '../../domain/feed_share.dart';
import '../../domain/story_user.dart';

/// Các bản ghi Công khai hôm nay (giờ VN) của [ownerId], sớm nhất trước.
List<FeedShare> sharesOfToday(Iterable<FeedShare> shares, String ownerId, {DateTime? now}) {
  final today = now ?? DateTime.now();
  return shares.where((s) => s.ownerId == ownerId && VnTime.isSameDay(s.occurredAt, today)).toList()
    ..sort((a, b) => a.occurredAt.compareTo(b.occurredAt));
}

/// "Ngày của bạn bè" (SOC-08): một vòng Dial thu nhỏ chỉ gồm những chấm Công khai hôm nay của một
/// người, xếp từ vòng trong ra ngoài theo thứ tự thời gian như vòng Dial ở màn hình chính.
class FriendDayDial extends StatelessWidget {
  const FriendDayDial({super.key, required this.user, required this.shares, this.isMe = false});

  final StoryUser user;

  /// Đã lọc bằng [sharesOfToday].
  final List<FeedShare> shares;
  final bool isMe;

  static const _ringRadius = [44.0, 80.0, 112.0];
  static const _dialSize = 268.0;

  @override
  Widget build(BuildContext context) {
    final shown = shares.take(maxEventTypes).toList();
    final sizes = dialRingSizes(shown.length);
    final positions = <Offset>[];
    for (var ring = 0; ring < sizes.length; ring++) {
      for (var i = 0; i < sizes[ring]; i++) {
        final a = -pi / 2 + 2 * pi * i / sizes[ring] + (ring.isOdd ? pi / sizes[ring] : 0);
        positions.add(Offset(cos(a), sin(a)) * _ringRadius[ring]);
      }
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEDE4D6)),
      ),
      child: Column(
        children: [
          Text(
            isMe ? 'Ngày của bạn' : 'Ngày của ${user.name}',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF261E1A)),
          ),
          const SizedBox(height: 2),
          Text(
            shown.isEmpty
                ? (isMe ? 'Hôm nay bạn chưa chấm Công khai gì' : 'Hôm nay ${user.name} chưa chấm Công khai gì')
                : '${shown.length} chấm Công khai hôm nay',
            style: const TextStyle(fontSize: 12.5, color: Color(0xFF8A7E74)),
          ),
          SizedBox(
            width: _dialSize,
            height: _dialSize,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size.square(_dialSize),
                  painter: OrbitalDialPainter(r1: _ringRadius[0], r2: _ringRadius[1], r3: _ringRadius[2]),
                ),
                UserAvatar(
                  name: user.name,
                  emoji: user.avatarEmoji,
                  imageUrl: user.avatarUrl,
                  radius: 26,
                  backgroundColor: Colors.white,
                ),
                for (var i = 0; i < shown.length; i++)
                  Transform.translate(
                    offset: positions[i],
                    child: _DayNode(
                      share: shown[i],
                      delay: Duration(milliseconds: 90 * i),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Một chấm trên vòng: emoji trong vòng tròn trắng, nảy vào lần lượt; giữ lâu để xem giờ.
class _DayNode extends StatelessWidget {
  const _DayNode({required this.share, required this.delay});

  final FeedShare share;
  final Duration delay;

  static const _pop = Duration(milliseconds: 420);

  @override
  Widget build(BuildContext context) {
    final total = delay + _pop;
    final start = delay.inMilliseconds / total.inMilliseconds;
    return Tooltip(
      message: '${share.name} · ${VnTime.hm(share.occurredAt)}',
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: total,
        builder: (context, t, child) {
          final local = t <= start ? 0.0 : (t - start) / (1 - start);
          return Transform.scale(scale: Curves.easeOutBack.transform(local), child: child);
        },
        child: Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFF2D9CC)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF6F52).withValues(alpha: 0.14),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(share.emoji, style: const TextStyle(fontSize: 17)),
        ),
      ),
    );
  }
}
