import 'package:flutter/material.dart';

import '../../domain/feed_item.dart';
import '../widgets/feed_card.dart';
import '../widgets/header_bar.dart';
import '../widgets/stories_bar.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({
    super.key,
    this.onNavigateToHome,
  });

  final VoidCallback? onNavigateToHome;

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  // Selected user filter ('Tất cả' shows all posts)
  String _selectedUser = 'Tất cả';

  // Story bar users list
  final List<StoryUser> _storyUsers = const [
    StoryUser(
      id: 'u1',
      name: 'Bạn',
      avatarUrl:
          'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
    ),
    StoryUser(
      id: 'u2',
      name: 'Minh Thư',
      avatarUrl:
          'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=150',
    ),
    StoryUser(
      id: 'u3',
      name: 'Hoàng Long',
      avatarUrl:
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
    ),
    StoryUser(
      id: 'u4',
      name: 'An Nhiên',
      avatarUrl:
          'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150',
    ),
    StoryUser(
      id: 'u5',
      name: 'Đức',
      avatarUrl:
          'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150',
    ),
  ];

  // Initial feed data array
  late List<FeedItem> _feedItems;

  @override
  void initState() {
    super.initState();
    _feedItems = [
      const FeedItem(
        id: '1',
        userName: 'Bạn',
        avatarUrl:
            'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
        actionText: 'đã uống cà phê sáng',
        isHighlightedAction: true,
        timestamp: 'vừa xong',
        badgeIcon: Icons.local_cafe_rounded,
        badgeColor: Color(0xFFE65100),
        selectedReaction: '❤️',
      ),
      const FeedItem(
        id: '2',
        userName: 'Minh Thư',
        avatarUrl:
            'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=150',
        actionText: 'đã hoàn thành chạy bộ 5km',
        isHighlightedAction: false,
        timestamp: '15 phút trước',
        badgeIcon: Icons.directions_run_rounded,
        badgeColor: Color(0xFF2E7D32),
        selectedReaction: null,
      ),
      const FeedItem(
        id: '3',
        userName: 'Hoàng Long',
        avatarUrl:
            'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
        actionText: 'đã đọc sách 30 phút',
        isHighlightedAction: false,
        timestamp: '42 phút trước',
        badgeIcon: Icons.menu_book_rounded,
        badgeColor: Color(0xFF1565C0),
        selectedReaction: '👍',
      ),
      const FeedItem(
        id: '4',
        userName: 'An Nhiên',
        avatarUrl:
            'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150',
        actionText: 'đã uống 500ml nước',
        isHighlightedAction: false,
        timestamp: '1 giờ trước',
        badgeIcon: Icons.water_drop_rounded,
        badgeColor: Color(0xFF0288D1),
        selectedReaction: null,
      ),
      const FeedItem(
        id: '5',
        userName: 'Đức',
        avatarUrl:
            'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150',
        actionText: 'đã đi ngủ sớm',
        isHighlightedAction: false,
        timestamp: 'Hôm qua',
        badgeIcon: Icons.bedtime_rounded,
        badgeColor: Color(0xFF512DA8),
        selectedReaction: '😊',
      ),
    ];
  }

  // Filter feed items based on selected user
  List<FeedItem> get _filteredFeedItems {
    if (_selectedUser == 'Tất cả') {
      return _feedItems;
    }
    return _feedItems.where((item) => item.userName == _selectedUser).toList();
  }

  void _onReactionTap(FeedItem item, String emoji) {
    setState(() {
      _feedItems = _feedItems.map((feed) {
        if (feed.id == item.id) {
          final isSameReaction = feed.selectedReaction == emoji;
          return feed.copyWith(
            selectedReaction: () => isSameReaction ? null : emoji,
          );
        }
        return feed;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF6F0),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Header Bar
            HeaderBar(
              onBackPressed: widget.onNavigateToHome ??
                  (Navigator.of(context).canPop()
                      ? () => Navigator.of(context).pop()
                      : null),
              onSettingsPressed: () => Navigator.pushNamed(context, '/widgets'),
              onProfilePressed: () => Navigator.pushNamed(context, '/add-qr'),
            ),

            // 2. Horizontal Filter / Stories Bar
            StoriesBar(
              users: _storyUsers,
              selectedUser: _selectedUser,
              onSelectUser: (user) {
                setState(() {
                  _selectedUser = user;
                });
              },
            ),

            // 3. Feed Cards List
            Expanded(
              child: _filteredFeedItems.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.inbox_outlined,
                              size: 48,
                              color: Color(0xFF6E655F),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Chưa có hoạt động nào từ "$_selectedUser"',
                              style: const TextStyle(
                                fontSize: 15,
                                color: Color(0xFF6E655F),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(top: 8.0, bottom: 24.0),
                      itemCount: _filteredFeedItems.length,
                      itemBuilder: (context, index) {
                        final item = _filteredFeedItems[index];
                        return FeedCard(
                          item: item,
                          onReactionTap: (emoji) =>
                              _onReactionTap(item, emoji),
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
