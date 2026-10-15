import 'package:flutter/material.dart';

import '../../domain/feed_item.dart';
import '../widgets/feed_card.dart';
import '../widgets/header_bar.dart';
import '../widgets/stories_bar.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

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
        actionText: 'đã chạy bộ ven hồ Tây',
        isHighlightedAction: false,
        timestamp: '15 phút trước',
        badgeIcon: Icons.directions_run_rounded,
        badgeColor: Color(0xFFD32F2F),
        selectedReaction: null,
      ),
      const FeedItem(
        id: '3',
        userName: 'Hoàng Long',
        avatarUrl:
            'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
        actionText: 'đã đọc xong một chương sách',
        isHighlightedAction: false,
        timestamp: '45 phút trước',
        badgeIcon: Icons.menu_book_rounded,
        badgeColor: Color(0xFF7B1FA2),
        selectedReaction: null,
      ),
    ];
  }

  void _toggleReaction(String itemId, String emoji) {
    setState(() {
      _feedItems = _feedItems.map((item) {
        if (item.id == itemId) {
          final newReaction = item.selectedReaction == emoji ? null : emoji;
          return item.copyWith(selectedReaction: () => newReaction);
        }
        return item;
      }).toList();
    });
  }

  List<FeedItem> get _filteredFeedItems {
    if (_selectedUser == 'Tất cả') {
      return _feedItems;
    }
    return _feedItems.where((item) => item.userName == _selectedUser).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF18181C), // Outer desktop canvas background
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 448), // max-w-md
          margin: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
          decoration: BoxDecoration(
            color: const Color(0xFFFDFBF7), // Warm off-white
            borderRadius: BorderRadius.circular(24.0), // rounded-3xl
            border: Border.all(
              color: const Color(0xFF5B58EB), // Purple-blue frame
              width: 8.0, // border-8
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: SafeArea(
            child: Column(
              children: [
                // 1. Header Bar
                const HeaderBar(),

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
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: _filteredFeedItems.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final item = _filteredFeedItems[index];
                            return FeedCard(
                              item: item,
                              onReactionTap: (emoji) =>
                                  _toggleReaction(item.id, emoji),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
