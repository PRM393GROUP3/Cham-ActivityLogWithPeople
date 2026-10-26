import 'package:characters/characters.dart';

/// Emoji gợi ý cho avatar.
const avatarEmojiChoices = [
  '😀', '😎', '🥰', '🤓', '😴', '🤠', '🥳', '😇', '🙃', '🤗',
  '🐱', '🐶', '🐼', '🦊', '🐻', '🐰', '🐨', '🐯', '🦁', '🐸',
  '🐧', '🐥', '🦄', '🐙', '🐳', '🦋', '🌸', '🌻', '🌵', '🍀',
  '☕', '🍵', '🍩', '🍉', '🍜', '⚽', '🎧', '🎨', '📚', '🚀',
  '⭐', '🌙', '🔥', '🌈', '💎', '🎈',
];

/// Đúng một emoji theo cách người dùng nhìn thấy (một grapheme, kể cả 👩‍💻, 👍🏽, 🇻🇳).
/// Server kiểm tra lại cùng quy tắc.
bool isSingleEmoji(String value) {
  final v = value.trim();
  if (v.characters.length != 1) return false;
  return v.runes.any(_isEmojiRune);
}

bool _isEmojiRune(int r) =>
    (r >= 0x1F000 && r <= 0x1FAFF) || // emoji, cờ (regional indicator), biểu tượng
    (r >= 0x2190 && r <= 0x2BFF) || // mũi tên, ký hiệu kỹ thuật, ☕ ⚽ ⭐…
    const {0x00A9, 0x00AE, 0x2122, 0x2139, 0x3030, 0x303D, 0x3297, 0x3299}.contains(r);
