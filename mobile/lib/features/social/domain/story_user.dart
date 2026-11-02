/// Một người trên thanh lọc phía trên feed.
class StoryUser {
  const StoryUser({
    required this.id,
    required this.name,
    this.avatarEmoji,
    this.avatarUrl,
  });

  final String id;
  final String name;

  /// Avatar emoji; chưa có thì hiển thị chữ cái đầu của tên.
  final String? avatarEmoji;

  /// Ảnh avatar, ưu tiên hơn [avatarEmoji].
  final String? avatarUrl;
}
