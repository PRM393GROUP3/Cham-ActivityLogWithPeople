# Social Activity News Feed UI Documentation

This document describes the architecture, reusable components, data models, and usage examples for the mobile-first Social Activity News Feed feature in the **Chấm** application.

---

## 📁 Directory Structure

```text
mobile/lib/features/social/
├── domain/
│   ├── feed_share.dart        # FeedShare: một bản ghi Công khai của bạn bè (từ GET /api/feed)
│   ├── reaction.dart          # Reaction: bộ 7 reaction giống Facebook (khớp REACTIONS ở backend)
│   └── story_user.dart        # StoryUser: một người trên thanh lọc
├── data/
│   └── feed_api.dart          # FeedApi: GET /api/feed, PUT/DELETE /api/feed/:id/reaction
└── presentation/
    ├── controllers/
    │   └── feed_controller.dart  # FeedController (AsyncNotifier): tải feed, thả/đổi/gỡ reaction
    ├── pages/
    │   └── feed_page.dart     # Màn hình feed (ConsumerStatefulWidget)
    └── widgets/
        ├── header_bar.dart    # Top App Header Bar
        ├── stories_bar.dart   # Horizontal Story / Filter Bar
        └── feed_card.dart     # Reusable Feed Activity Card
```

Danh sách bạn bè cho thanh lọc lấy từ `friendsControllerProvider` (feature `friends`).

---

## 1. Data Models (`domain/`)

### `FeedShare`
Một bản ghi **Công khai** của bạn bè (SOC-05). Parse từ phần tử của `GET /api/feed`.

| Field | Type | Ý nghĩa |
| :--- | :--- | :--- |
| `id` | `String` | id bản chia sẻ (= UUID bản ghi của chủ) |
| `ownerId`, `ownerName` | `String` | người chia sẻ |
| `emoji`, `name` | `String` | loại sự kiện, vd. `🏃` `Chạy bộ` |
| `occurredAt` | `DateTime` | thời điểm chạm nút gốc |
| `reactionCounts` | `Map<String, int>` | số người đã thả từng emoji |
| `myReaction` | `String?` | reaction của chính mình (tối đa 1) |
| `isMine` | `bool` | bài của chính mình (từ `GET /api/shares`): không tự thả cảm xúc được |
| `reactors` | `List<Reactor>` | (bài của mình) ai đã thả gì: `userId, displayName, avatarEmoji, emoji, reactedAt` |

- `withMyReaction(String? emoji)`: trả bản sao với reaction của mình đổi sang `emoji` (hoặc gỡ khi `null`), cập nhật số đếm — dùng cho cập nhật lạc quan (optimistic).

### `Reaction`
```dart
enum Reaction { like('👍','Thích'), love('❤️','Yêu thích'), care('🥰','Thương thương'),
                haha('😆','Haha'), wow('😮','Wow'), sad('😢','Buồn'), angry('😡','Phẫn nộ') }
```

### `StoryUser`
`{ id, name, avatarUrl? }` — chưa có ảnh thì hiển thị chữ cái đầu của tên.

---

## 2. State (`presentation/controllers/feed_controller.dart`)

`feedControllerProvider` — `AsyncNotifier<List<FeedShare>>`:
- `build()`: đảm bảo có tài khoản ẩn danh (tự đăng ký lần đầu, cần mạng), tải song song `GET /api/feed` (bạn bè) và `GET /api/shares` (của mình → `FeedShare.fromOwnJson`), gộp và xếp mới nhất trước.
- Tự tải lại khi `ActivityDialController` gửi xong một thay đổi chia sẻ.
- `refresh()`: tải lại (kéo xuống để làm mới).
- `toggleReaction(shareId, emoji)`: chạm emoji chưa chọn → thả / đổi; chạm lại emoji đang chọn → gỡ. Cập nhật UI ngay, **hoàn tác** nếu server từ chối và ném lỗi để UI hiện SnackBar.

---

## 3. Reusable Widgets

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
| `users` | `List<StoryUser>` | Yes | Bạn bè hiển thị trên thanh lọc. |
| `selectedUserId` | `String?` | Yes | Người đang được lọc; `null` = `"Tất cả"`. |
| `onSelectUser` | `ValueChanged<String?>` | Yes | Gọi khi chọn một người (`null` khi chọn `"Tất cả"`). |

#### Usage Example
```dart
StoriesBar(
  users: [for (final f in friends) StoryUser(id: f.id, name: f.displayName)],
  selectedUserId: _selectedUserId,
  onSelectUser: (id) => setState(() => _selectedUserId = id),
)
```

---

### C. `FeedCard` (`widgets/feed_card.dart`)
Một thẻ hoạt động: avatar chữ cái đầu + emoji hoạt động ở góc, câu *"Minh Thư đã chấm 🏃 Chạy bộ"*, thời gian tương đối theo giờ Việt Nam (`VnTime.relative`), và thanh **7 reaction** kèm số đếm.

#### Constructor Parameters
| Parameter | Type | Required | Description |
| :--- | :--- | :--- | :--- |
| `share` | `FeedShare` | Yes | Bản ghi Công khai cần hiển thị. |
| `onReactionTap` | `ValueChanged<String>` | Yes | Gọi với emoji vừa chạm. |

#### Usage Example
```dart
FeedCard(
  share: share,
  onReactionTap: (emoji) => ref.read(feedControllerProvider.notifier).toggleReaction(share.id, emoji),
)
```

---

## 4. Main Screen Page (`pages/feed_page.dart`)

`FeedPage` (ConsumerStatefulWidget) ghép `HeaderBar`, `StoriesBar` và danh sách `FeedCard`:

| Trạng thái | Hiển thị |
| :--- | :--- |
| Đang tải | vòng xoay |
| Lỗi (vd. mất mạng lần đầu) | thông báo lỗi + nút **Thử lại** |
| Chưa có bạn bè | *"Chưa có bạn bè nào…"* + nút **Mở mã QR** |
| Có bạn nhưng chưa ai Công khai | *"Chưa có hoạt động công khai nào."* |
| Có dữ liệu | danh sách thẻ, kéo xuống để tải lại |

---

## 🎨 Color Palette Reference

| Color Name | Hex Code | Usage |
| :--- | :--- | :--- |
| Outer Frame Border | `#5B58EB` | 8px outer viewport frame border |
| Primary Frame Background | `#FDFBF7` | Warm off-white viewport background |
| Card & Story Strip Background | `#F3EFEA` | Feed cards and story strip container background |
| Primary Text | `#1E1B18` | Deep charcoal for names and titles |
| Timestamps & Icons | `#6E655F` | Muted brown-gray for timestamps and clock icons |
| Coral Dot & Accent | `#FF6B4A` | Coral dot next to logo, "Tất cả" active highlight |
| Dark Brown Badge | `#3E2723` | Checkmark badge background on selected "Tất cả" |
| Soft Pink Highlight | `#FADCD9` | Background pill for active emoji reaction |
| Reaction Pill Container | `#FAF8F5` | White/cream background for reaction bar |
