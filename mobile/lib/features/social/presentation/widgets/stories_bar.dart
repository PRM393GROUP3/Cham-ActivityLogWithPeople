import 'package:flutter/material.dart';

import '../../../account/presentation/widgets/user_avatar.dart';
import '../../domain/story_user.dart';

class StoriesBar extends StatelessWidget {
  const StoriesBar({
    super.key,
    required this.users,
    required this.selectedUserId,
    required this.onSelectUser,
  });

  final List<StoryUser> users;

  /// `null` = "Tất cả".
  final String? selectedUserId;
  final ValueChanged<String?> onSelectUser;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF3EFEA),
        border: Border.symmetric(
          horizontal: BorderSide(
            color: Color(0xFFEAE3DC),
            width: 1.0,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          children: [
            // "Tất cả" Item
            _buildAllItem(),
            const SizedBox(width: 20),

            // User Items
            for (final user in users) ...[
              _buildUserItem(user),
              const SizedBox(width: 20),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAllItem() {
    final isSelected = selectedUserId == null;

    return GestureDetector(
      onTap: () => onSelectUser(null),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: Stack(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B4A),
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(color: const Color(0xFF3E2723), width: 2.5)
                        : null,
                  ),
                  child: const Icon(
                    Icons.public,
                    color: Colors.white,
                    size: 30,
                  ),
                ),

                // Dark Brown Checkmark Badge at Bottom Right when selected
                if (isSelected)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3E2723),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFF3EFEA), width: 1.5),
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tất cả',
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: isSelected ? const Color(0xFFFF6B4A) : const Color(0xFF1E1B18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserItem(StoryUser user) {
    final isSelected = selectedUserId == user.id;

    return GestureDetector(
      onTap: () => onSelectUser(user.id),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: Stack(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFFFF6B4A)
                          : const Color(0xFFE6DFD5),
                      width: isSelected ? 3.0 : 2.0,
                    ),
                  ),
                  child: UserAvatar(name: user.name, emoji: user.avatarEmoji, radius: 29),
                ),
                if (isSelected)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6B4A),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFF3EFEA), width: 1.5),
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            user.name,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? const Color(0xFFFF6B4A) : const Color(0xFF1E1B18),
            ),
          ),
        ],
      ),
    );
  }
}
