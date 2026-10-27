import 'dart:math';

final _random = Random.secure();

/// UUID v4 chuẩn RFC 4122 dạng `xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx`.
/// Dùng làm id bản ghi local và id bản chia sẻ trên server (BR-04).
String uuidV4() {
  final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
  bytes[8] = (bytes[8] & 0x3f) | 0x80; // variant
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-'
      '${hex.substring(16, 20)}-${hex.substring(20)}';
}
