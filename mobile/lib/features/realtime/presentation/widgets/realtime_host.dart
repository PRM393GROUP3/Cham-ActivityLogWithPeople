import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../account/presentation/widgets/user_avatar.dart';
import '../realtime_controller.dart';

/// Bọc toàn bộ app: giữ kết nối realtime và hiện thông báo trượt xuống ở đầu màn hình khi bạn bè
/// thả cảm xúc vào bài của mình, kèm emoji cảm xúc bay lên.
class RealtimeHost extends ConsumerStatefulWidget {
  const RealtimeHost({super.key, required this.child});

  final Widget child;

  static const visibleFor = Duration(milliseconds: 3800);

  @override
  ConsumerState<RealtimeHost> createState() => _RealtimeHostState();
}

class _RealtimeHostState extends ConsumerState<RealtimeHost> {
  ReactionNotice? _notice;
  bool _visible = false;
  Timer? _hide;

  @override
  void dispose() {
    _hide?.cancel();
    super.dispose();
  }

  void _show(ReactionNotice notice) {
    _hide?.cancel();
    setState(() {
      _notice = notice;
      _visible = true;
    });
    _hide = Timer(RealtimeHost.visibleFor, () {
      if (mounted) setState(() => _visible = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(realtimeControllerProvider, (_, next) {
      if (next != null) _show(next);
    });
    final notice = _notice;

    return Stack(
      children: [
        widget.child,
        if (notice != null)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 380),
            curve: Curves.easeOutBack,
            left: 12,
            right: 12,
            top: _visible ? MediaQuery.paddingOf(context).top + 10 : -140,
            child: GestureDetector(
              onTap: () => setState(() => _visible = false),
              child: _ReactionBanner(key: ValueKey(notice.seq), notice: notice),
            ),
          ),
      ],
    );
  }
}

class _ReactionBanner extends StatelessWidget {
  const _ReactionBanner({super.key, required this.notice});

  final ReactionNotice notice;

  @override
  Widget build(BuildContext context) {
    final r = notice.reactor;
    return Material(
      color: const Color(0xFF2B221D),
      elevation: 8,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
        child: Row(
          children: [
            UserAvatar(name: r.displayName, emoji: r.avatarEmoji, imageUrl: r.avatarUrl, radius: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${r.displayName} đã thả ${r.emoji}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'vào ${notice.shareEmoji} ${notice.shareName} của bạn',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Color(0xFFD9CBBF), fontSize: 12.5),
                  ),
                ],
              ),
            ),
            _FloatingEmoji(emoji: r.emoji),
          ],
        ),
      ),
    );
  }
}

/// Emoji cảm xúc nảy lên rồi lơ lửng — để thông báo có cảm giác "vừa được gửi tới".
class _FloatingEmoji extends StatelessWidget {
  const _FloatingEmoji({required this.emoji});

  final String emoji;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: Curves.elasticOut,
      builder: (context, t, child) => Transform.translate(
        offset: Offset(0, 10 * (1 - t)),
        child: Transform.scale(scale: 0.4 + 0.6 * t, child: child),
      ),
      child: Text(emoji, style: const TextStyle(fontSize: 30)),
    );
  }
}
