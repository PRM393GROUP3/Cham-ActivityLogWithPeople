import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../account/presentation/account_controller.dart';
import '../../../friends/presentation/controllers/friends_controller.dart';
import '../../domain/feed_share.dart';
import '../../domain/story_user.dart';
import '../controllers/feed_controller.dart';
import '../widgets/feed_card.dart';
import '../widgets/friend_day_dial.dart';
import '../widgets/stories_bar.dart';

/// Feed các bản ghi Public của bạn bè (SOC-05). Lọc theo từng người bằng thanh phía trên.
class FeedPage extends ConsumerStatefulWidget {
  const FeedPage({
    super.key,
    this.onNavigateToHome,
  });

  final VoidCallback? onNavigateToHome;

  @override
  ConsumerState<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends ConsumerState<FeedPage> {
  /// `null` = "Tất cả".
  String? _selectedUserId;

  Future<void> _refresh() => Future.wait([
        ref.read(feedControllerProvider.notifier).refresh(),
        ref.read(friendsControllerProvider.notifier).refresh(),
      ]);

  /// Đã về Trang chủ trong lần kéo này (chỉ gọi một lần mỗi lần kéo).
  bool _leaving = false;

  /// Quãng ngón tay đã kéo xuống khi danh sách đang ở đầu (chưa trừ ma sát bật nảy).
  double _pull = 0;
  static const _pullToHome = 56.0;

  /// Trong shell: kéo xuống quá đầu danh sách thì về Trang chủ (Trang chủ nằm phía trên),
  /// làm mới bằng nút trên header. Đứng riêng thì kéo xuống để làm mới như thường.
  Widget _pullable(Widget list) {
    final onHome = widget.onNavigateToHome;
    if (onHome == null) return RefreshIndicator(onRefresh: _refresh, child: list);
    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n is ScrollStartNotification) {
          _leaving = false;
          _pull = 0;
        }
        final drag = switch (n) {
          ScrollUpdateNotification(:final dragDetails?) => dragDetails,
          OverscrollNotification(:final dragDetails?) => dragDetails,
          _ => null,
        };
        if (drag != null) {
          final atTop = n.metrics.pixels <= n.metrics.minScrollExtent;
          _pull = atTop ? _pull + drag.delta.dy : 0;
          if (!_leaving && _pull > _pullToHome) {
            _leaving = true;
            onHome();
          }
        }
        return false;
      },
      child: list,
    );
  }

  Future<void> _onReactionTap(FeedShare share, String emoji) async {
    try {
      await ref.read(feedControllerProvider.notifier).toggleReaction(share.id, emoji);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thả được reaction: $e'), behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final feed = ref.watch(feedControllerProvider);
    final friends = ref.watch(friendsControllerProvider).value ?? const [];
    final me = ref.watch(accountControllerProvider).value;
    final storyUsers = [
      // "Bạn": lọc bài Công khai của chính mình để xem bạn bè đã thả cảm xúc gì.
      if (me != null) StoryUser(id: me.id, name: 'Bạn', avatarEmoji: me.avatarEmoji),
      for (final f in friends) StoryUser(id: f.id, name: f.displayName, avatarEmoji: f.avatarEmoji),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFFAF6F0),
      body: SafeArea(
        child: Column(
          children: [
            if (widget.onNavigateToHome != null) _HomeGrip(onTap: widget.onNavigateToHome!),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 8, 6),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Bạn bè',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1E1B18)),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Làm mới',
                    icon: const Icon(Icons.refresh_rounded, color: Color(0xFF5C4033)),
                    onPressed: _refresh,
                  ),
                  IconButton(
                    tooltip: 'Mã QR kết bạn',
                    icon: const Icon(Icons.qr_code_2_rounded, color: Color(0xFF5C4033)),
                    onPressed: () => Navigator.pushNamed(context, '/add-qr'),
                  ),
                ],
              ),
            ),

            StoriesBar(
              users: storyUsers,
              selectedUserId: _selectedUserId,
              onSelectUser: (id) => setState(() => _selectedUserId = id),
            ),

            Expanded(
              child: feed.when(
                skipLoadingOnRefresh: true,
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => _Message(
                  icon: Icons.cloud_off_rounded,
                  text: '$error',
                  actionLabel: 'Thử lại',
                  onAction: _refresh,
                ),
                data: (shares) {
                  final visible = _selectedUserId == null
                      ? shares
                      : shares.where((s) => s.ownerId == _selectedUserId).toList();
                  // Chọn một người: "Ngày của …" (SOC-08) đứng đầu danh sách bài của người đó.
                  final selected = storyUsers.where((u) => u.id == _selectedUserId).firstOrNull;
                  final dayDial = selected == null
                      ? null
                      : FriendDayDial(
                          key: ValueKey('day-${selected.id}'),
                          user: selected,
                          shares: sharesOfToday(shares, selected.id),
                          isMe: selected.id == me?.id,
                        );
                  return _pullable(
                    visible.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                            padding: dayDial == null ? null : const EdgeInsets.fromLTRB(16, 12, 16, 24),
                            children: [
                              if (dayDial != null) ...[dayDial, const SizedBox(height: 12)],
                              _Message(
                                icon: Icons.inbox_outlined,
                                text: friends.isEmpty
                                    ? 'Chưa có bạn bè nào.\nKết bạn qua mã QR để xem hoạt động của nhau.'
                                    : 'Chưa có hoạt động công khai nào.',
                                actionLabel: friends.isEmpty ? 'Mở mã QR' : null,
                                onAction: friends.isEmpty ? () => Navigator.pushNamed(context, '/add-qr') : null,
                              ),
                            ],
                          )
                        : ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                            itemCount: visible.length + (dayDial == null ? 0 : 1),
                            separatorBuilder: (_, _) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              if (dayDial != null) {
                                if (index == 0) return dayDial;
                                index--;
                              }
                              final share = visible[index];
                              return FeedCard(
                                share: share,
                                onReactionTap: (emoji) => _onReactionTap(share, emoji),
                              );
                            },
                          ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Thanh kéo trên cùng: vuốt xuống (hoặc bấm) để về Trang chủ.
class _HomeGrip extends StatelessWidget {
  const _HomeGrip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Trang chủ',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        onVerticalDragEnd: (d) {
          if ((d.primaryVelocity ?? 0) > 0) onTap();
        },
        child: SizedBox(
          height: 22,
          width: double.infinity,
          child: Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFDCCFC3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text, this.actionLabel, this.onAction});

  final IconData icon;
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: const Color(0xFF6E655F)),
          const SizedBox(height: 12),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, color: Color(0xFF6E655F), fontWeight: FontWeight.w500),
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: 16),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFFB53216)),
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
