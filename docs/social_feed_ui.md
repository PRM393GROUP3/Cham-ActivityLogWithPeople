# Social Activity News Feed UI Documentation

This document describes the architecture, reusable components, data models, and usage examples for the mobile-first Social Activity News Feed feature in the **Chấm** application.

---

## 📁 Directory Structure

```text
mobile/lib/features/social/
├── domain/
│   └── feed_item.dart         # FeedItem & StoryUser data models
└── presentation/
    ├── pages/
    │   └── feed_page.dart     # Main Feed Page Screen with state
    └── widgets/
        ├── header_bar.dart    # Top App Header Bar
        ├── stories_bar.dart   # Horizontal Story / Filter Bar
        └── feed_card.dart     # Reusable Feed Activity Card
```

---

## 1. Data Models (`domain/feed_item.dart`)

### `StoryUser`
Represents a user shown in the horizontal story filter bar.

```dart
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
```

### `FeedItem`
Represents an individual social activity feed item.

#### Properties
- `id`: Unique identifier for the feed item.
- `userName`: Display name of the user who logged the activity.
- `avatarUrl`: URL string for the user's avatar image.
- `actionText`: Description of the action (e.g., `"đã uống cà phê sáng"`).
- `isHighlightedAction`: `bool` — if `true`, applies rust red styling (`#8C2D19`).
- `timestamp`: String formatted timestamp (e.g., `"vừa xong"`, `"15 phút trước"`).
- `badgeIcon`: `IconData` for the small activity badge on the avatar corner.
- `badgeColor`: `Color` for the activity badge icon.
- `selectedReaction`: `String?` — the active emoji reaction (`'❤️'`, `'👍'`, `'😊'`, `'😢'`, `'😆'`, or `null`).

#### Methods
- `copyWith(...)`: Helper method to return a modified immutable copy of `FeedItem`.

```dart
final item = FeedItem(
  id: '1',
  userName: 'Bạn',
  avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
  actionText: 'đã uống cà phê sáng',
  isHighlightedAction: true,
  timestamp: 'vừa xong',
  badgeIcon: Icons.local_cafe_rounded,
  badgeColor: Color(0xFFE65100),
  selectedReaction: '❤️',
);
```

---

## 2. Reusable Widgets

### A. `HeaderBar` (`widgets/header_bar.dart`)
Renders the top branding bar containing the title `"Chấm"` with a coral dot, along with settings and profile action buttons.

#### Constructor Parameters
| Parameter | Type | Required | Description |
| :--- | :--- | :--- | :--- |
| `onSettingsPressed` | `VoidCallback?` | No | Callback when settings gear icon is tapped. |
| `onProfilePressed` | `VoidCallback?` | No | Callback when profile circular button is tapped. |

#### Usage Example
```dart
HeaderBar(
  onSettingsPressed: () => print('Settings tapped'),
  onProfilePressed: () => print('Profile tapped'),
)
```

---

### B. `StoriesBar` (`widgets/stories_bar.dart`)
Renders a horizontal scrollable strip containing the `"Tất cả"` global filter item and individual user story avatars.

#### Constructor Parameters
| Parameter | Type | Required | Description |
| :--- | :--- | :--- | :--- |
| `users` | `List<StoryUser>` | Yes | List of user objects for the story avatars. |
| `selectedUser` | `String` | Yes | Currently active filter (`'Tất cả'` or user name). |
| `onSelectUser` | `ValueChanged<String>` | Yes | Callback invoked when a story item is selected. |

#### Usage Example
```dart
StoriesBar(
  users: myStoryUsersList,
  selectedUser: _selectedUser,
  onSelectUser: (String selectedName) {
    setState(() {
      _selectedUser = selectedName;
    });
  },
)
```

---

### C. `FeedCard` (`widgets/feed_card.dart`)
Renders a single activity card with user avatar, overlapping activity badge, activity line, timestamp, and an interactive 5-emoji reaction pill bar.

#### Constructor Parameters
| Parameter | Type | Required | Description |
| :--- | :--- | :--- | :--- |
| `item` | `FeedItem` | Yes | Data item containing card details and reaction state. |
| `onReactionTap` | `ValueChanged<String>` | Yes | Callback invoked when an emoji reaction button is tapped. |

#### Emoji Options
Supported reactions: `['❤️', '👍', '😊', '😢', '😆']`

#### Usage Example
```dart
FeedCard(
  item: feedItem,
  onReactionTap: (String emoji) {
    // Toggle reaction state
    setState(() {
      _feedItems = _feedItems.map((i) {
        if (i.id == feedItem.id) {
          final newReaction = i.selectedReaction == emoji ? null : emoji;
          return i.copyWith(selectedReaction: () => newReaction);
        }
        return i;
      }).toList();
    });
  },
)
```

---

## 3. Main Screen Page (`pages/feed_page.dart`)

`FeedPage` integrates all reusable components inside a centered mobile viewport container (`maxWidth: 448px`) with a 8px purple-blue border frame (`#5B58EB`).

```dart
// To navigate to or render the FeedPage in your app:
import 'features/social/presentation/pages/feed_page.dart';

class MyApp extends StatelessWidget {
  @write
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: FeedPage(),
    );
  }
}
```

---

## 🎨 Color Palette Reference

| Color Name | Hex Code | Usage |
| :--- | :--- | :--- |
| Outer Frame Border | `#5B58EB` | 8px outer viewport frame border |
| Primary Frame Background | `#FDFBF7` | Warm off-white viewport background |
| Card & Story Strip Background | `#F3EFEA` | Feed cards and story strip container background |
| Primary Text | `#1E1B18` | Deep charcoal for names and titles |
| Timestamps & Icons | `#6E655F` | Muted brown-gray for timestamps and clock icons |
| Highlighted Action | `#8C2D19` | Rust red for highlighted activity descriptions |
| Coral Dot & Accent | `#FF6B4A` | Coral dot next to logo, "Tất cả" active highlight |
| Dark Brown Badge | `#3E2723` | Checkmark badge background on selected "Tất cả" |
| Soft Pink Highlight | `#FADCD9` | Background pill for active emoji reaction |
| Reaction Pill Container | `#FAF8F5` | White/cream background for reaction bar |
