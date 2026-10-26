import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../friends/presentation/controllers/friends_controller.dart';
import '../../domain/feed_share.dart';
import '../../domain/story_user.dart';
import '../controllers/feed_controller.dart';
import '../widgets/feed_card.dart';
import '../widgets/header_bar.dart';
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
    final storyUsers = [for (final f in friends) StoryUser(id: f.id, name: f.displayName)];

    return Scaffold(
      backgroundColor: const Color(0xFFFAF6F0),
      body: SafeArea(
        child: Column(
          children: [
            HeaderBar(
              onBackPressed: widget.onNavigateToHome ??
                  (Navigator.of(context).canPop()
                      ? () => Navigator.of(context).pop()
                      : null),
              onSettingsPressed: () => Navigator.pushNamed(context, '/widgets'),
              onProfilePressed: () => Navigator.pushNamed(context, '/add-qr'),
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
                  return RefreshIndicator(
                    onRefresh: _refresh,
                    child: visible.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
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
                            itemCount: visible.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
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
