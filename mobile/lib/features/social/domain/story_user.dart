/// Một người trên thanh lọc phía trên feed.
class StoryUser {
  const StoryUser({
    required this.id,
    required this.name,
    this.avatarUrl,
  });

  final String id;
  final String name;

  /// Chưa có ảnh đại diện thì hiển thị chữ cái đầu của tên.
  final String? avatarUrl;
}
