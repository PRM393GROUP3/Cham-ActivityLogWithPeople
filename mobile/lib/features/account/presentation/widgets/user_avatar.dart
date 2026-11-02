import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../core/config/env.dart';

/// Avatar của một người dùng: ảnh họ tải lên, emoji họ chọn, hoặc chữ cái đầu của tên khi chưa chọn.
/// Trong lúc ảnh đang tải (hoặc tải lỗi) thì hiện emoji / chữ cái đầu.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.name,
    this.emoji,
    this.imageUrl,
    this.imageBytes,
    this.radius = 22,
    this.backgroundColor,
  });

  final String name;
  final String? emoji;

  /// `avatarUrl` server trả về (`/api/avatars/...`, tính theo gốc API) hoặc URL tuyệt đối.
  final String? imageUrl;

  /// Ảnh vừa chọn trên máy, chưa tải lên; ưu tiên hơn [imageUrl].
  final Uint8List? imageBytes;
  final double radius;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final hasEmoji = emoji != null && emoji!.isNotEmpty;
    final ImageProvider? image = imageBytes != null
        ? MemoryImage(imageBytes!)
        : imageUrl != null
            ? NetworkImage(resolveAvatarUrl(imageUrl!))
            : null;
    return Container(
      width: radius * 2,
      height: radius * 2,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: backgroundColor ?? (hasEmoji ? const Color(0xFFFFF4EC) : const Color(0xFFE6DFD5)),
        shape: BoxShape.circle,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            hasEmoji ? emoji! : (name.isNotEmpty ? name.characters.first.toUpperCase() : '?'),
            style: hasEmoji
                ? TextStyle(fontSize: radius * 1.05, height: 1.1)
                : TextStyle(fontSize: radius * 0.8, fontWeight: FontWeight.bold, color: const Color(0xFF1E1B18)),
          ),
          if (image != null)
            ClipOval(
              child: Image(
                image: image,
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
        ],
      ),
    );
  }
}

/// Đường dẫn avatar của server là tương đối (`/api/avatars/...`): ghép với gốc API.
String resolveAvatarUrl(String url) => url.startsWith('/') ? '${Env.apiBaseUrl}$url' : url;
