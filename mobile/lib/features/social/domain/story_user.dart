/// Một người trên thanh lọc phía trên feed.
class StoryUser {
  const StoryUser({
    required this.id,
    required this.name,
    this.avatarEmoji,
  });

  final String id;
  final String name;

  /// Avatar emoji; chưa có thì hiển thị chữ cái đầu của tên.
  final String? avatarEmoji;
}
