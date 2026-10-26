/// Bộ reaction giống Facebook (SOC-05). Phải khớp `REACTIONS` ở backend.
enum Reaction {
  like('👍', 'Thích'),
  love('❤️', 'Yêu thích'),
  care('🥰', 'Thương thương'),
  haha('😆', 'Haha'),
  wow('😮', 'Wow'),
  sad('😢', 'Buồn'),
  angry('😡', 'Phẫn nộ');

  const Reaction(this.emoji, this.label);

  final String emoji;
  final String label;
}
