import 'package:flutter/material.dart';

class StoryUser {
  final String id;
  final String name;
  final String avatarUrl;

  const StoryUser({
    required this.id,
    required this.name,
    required this.avatarUrl,
  });
}

class FeedItem {
  final String id;
  final String userName;
  final String avatarUrl;
  final String actionText;
  final bool isHighlightedAction;
  final String timestamp;
  final IconData badgeIcon;
  final Color badgeColor;
  final String? selectedReaction;

  const FeedItem({
    required this.id,
    required this.userName,
    required this.avatarUrl,
    required this.actionText,
    this.isHighlightedAction = false,
    required this.timestamp,
    required this.badgeIcon,
    required this.badgeColor,
    this.selectedReaction,
  });

  FeedItem copyWith({
    String? id,
    String? userName,
    String? avatarUrl,
    String? actionText,
    bool? isHighlightedAction,
    String? timestamp,
    IconData? badgeIcon,
    Color? badgeColor,
    String? Function()? selectedReaction,
  }) {
    return FeedItem(
      id: id ?? this.id,
      userName: userName ?? this.userName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      actionText: actionText ?? this.actionText,
      isHighlightedAction: isHighlightedAction ?? this.isHighlightedAction,
      timestamp: timestamp ?? this.timestamp,
      badgeIcon: badgeIcon ?? this.badgeIcon,
      badgeColor: badgeColor ?? this.badgeColor,
      selectedReaction:
          selectedReaction != null ? selectedReaction() : this.selectedReaction,
    );
  }
}
