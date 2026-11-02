import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/network/api_exception.dart';
import '../../domain/avatar.dart';
import '../../domain/username.dart';
import '../account_controller.dart';
import '../widgets/avatar_emoji_grid.dart';
import '../widgets/user_avatar.dart';

/// Chọn một ảnh làm avatar; `null` khi người dùng huỷ.
typedef AvatarPhotoPicker = Future<Uint8List?> Function();

/// Thư viện ảnh, thu nhỏ còn ≤ 512px (JPEG) để tải lên nhanh và dưới giới hạn 2 MB của server.
Future<Uint8List?> _pickFromGallery() async {
  final file = await ImagePicker().pickImage(
    source: ImageSource.gallery,
    maxWidth: 512,
    maxHeight: 512,
    imageQuality: 85,
  );
  return file?.readAsBytes();
}

const _maxPhotoBytes = 2 * 1024 * 1024;

/// Đặt nickname (duy nhất), họ tên và avatar (ảnh hoặc emoji) — bạn bè thấy trong danh sách
/// bạn bè, feed và reaction.
/// Lưu lên server nên cần mạng; lần đầu sẽ tự tạo tài khoản ẩn danh.
class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key, this.pickPhoto = _pickFromGallery});

  /// Nguồn ảnh cho nút "Chọn ảnh" (thay được trong test).
  final AvatarPhotoPicker pickPhoto;

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _username = TextEditingController();
  final _name = TextEditingController();
  final _customEmoji = TextEditingController();
  String? _emoji;

  /// Ảnh avatar đang có trên server, giữ nguyên nếu không đổi.
  String? _photoUrl;

  /// Ảnh vừa chọn, tải lên khi bấm Lưu.
  Uint8List? _photo;
  bool _loaded = false;
  bool _saving = false;
  String? _usernameError;
  String? _error;

  @override
  void dispose() {
    _username.dispose();
    _name.dispose();
    _customEmoji.dispose();
    super.dispose();
  }

  /// Chọn emoji (hoặc `null` = bỏ avatar): bỏ luôn ảnh.
  void _pick(String? emoji) => setState(() {
        _emoji = emoji;
        _photo = null;
        _photoUrl = null;
        _error = null;
      });

  Future<void> _pickPhoto() async {
    final Uint8List? bytes;
    try {
      bytes = await widget.pickPhoto();
    } catch (_) {
      if (mounted) setState(() => _error = 'Không mở được thư viện ảnh.');
      return;
    }
    if (bytes == null || !mounted) return;
    if (bytes.length > _maxPhotoBytes) return setState(() => _error = 'Ảnh quá lớn (tối đa 2 MB).');
    setState(() {
      _photo = bytes;
      _photoUrl = null;
      _emoji = null;
      _customEmoji.clear();
      _error = null;
    });
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final usernameProblem = usernameError(_username.text);
    if (usernameProblem != null) return setState(() => _usernameError = usernameProblem);
    if (name.isEmpty) return setState(() => _error = 'Hãy nhập họ và tên.');
    if (name.characters.length > 50) return setState(() => _error = 'Họ và tên tối đa 50 ký tự.');
    if (_emoji != null && !isSingleEmoji(_emoji!)) {
      return setState(() => _error = 'Avatar phải là đúng một emoji.');
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final account = ref.read(accountControllerProvider.notifier);
      final keepPhoto = _photo != null || _photoUrl != null;
      await account.updateProfile(
        displayName: name,
        username: normalizeUsername(_username.text),
        avatarEmoji: keepPhoto ? null : () => _emoji?.trim(),
      );
      if (_photo != null) {
        await account.uploadAvatarPhoto(_photo!);
        _photo = null;
        _photoUrl = ref.read(accountControllerProvider).value?.avatarUrl;
      }
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã lưu hồ sơ'), behavior: SnackBarBehavior.floating),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        if (e.code == 'USERNAME_TAKEN') {
          _usernameError = e.message;
        } else {
          _error = 'Không lưu được: $e';
        }
      });
    } catch (e) {
      if (mounted) setState(() => _error = 'Không lưu được: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final account = ref.watch(accountControllerProvider).value;
    if (!_loaded && !ref.watch(accountControllerProvider).isLoading) {
      _loaded = true;
      _username.text = account?.username ?? '';
      _name.text = account?.displayName ?? AccountController.defaultDisplayName;
      _emoji = account?.avatarEmoji;
      _photoUrl = account?.avatarUrl;
    }
    final name = _name.text.trim().isEmpty ? '?' : _name.text.trim();

    return Scaffold(
      backgroundColor: const Color(0xFFFAF6F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF6F0),
        title: const Text('Hồ sơ của bạn', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Center(
            child: UserAvatar(name: name, emoji: _emoji, imageUrl: _photoUrl, imageBytes: _photo, radius: 44),
          ),
          const SizedBox(height: 8),
          const Text(
            'Bạn bè thấy nickname, họ tên và avatar này trong danh sách bạn bè và feed.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: Color(0xFF8A7E74)),
          ),
          const SizedBox(height: 20),
          TextField(
            key: const ValueKey('profile-username'),
            controller: _username,
            maxLength: usernameMaxLength,
            autocorrect: false,
            enableSuggestions: false,
            keyboardType: TextInputType.visiblePassword, // bàn phím không gợi ý / tự viết hoa
            inputFormatters: [FilteringTextInputFormatter.allow(usernameAllowedChars)],
            decoration: InputDecoration(
              labelText: 'Nickname',
              prefixText: '@',
              helperText: 'Duy nhất, bạn bè dùng để nhận ra bạn.',
              errorText: _usernameError,
              errorMaxLines: 2,
              border: const OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() => _usernameError = null),
          ),
          const SizedBox(height: 4),
          TextField(
            key: const ValueKey('profile-name'),
            controller: _name,
            maxLength: 50,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Họ và tên', border: OutlineInputBorder()),
            onChanged: (_) => setState(() => _error = null),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Expanded(child: Text('Avatar', style: TextStyle(fontWeight: FontWeight.w800))),
              TextButton.icon(
                onPressed: _saving ? null : _pickPhoto,
                icon: const Icon(Icons.photo_library_outlined, size: 18),
                label: const Text('Chọn ảnh'),
              ),
              TextButton.icon(
                onPressed: _emoji == null && _photo == null && _photoUrl == null ? null : () => _pick(null),
                icon: const Icon(Icons.close_rounded, size: 18),
                label: const Text('Bỏ avatar'),
              ),
            ],
          ),
          AvatarEmojiGrid(selected: _emoji, onPick: _pick),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('profile-custom-emoji'),
            controller: _customEmoji,
            decoration: const InputDecoration(
              labelText: 'Hoặc nhập emoji khác',
              hintText: 'vd. 👩‍💻',
              border: OutlineInputBorder(),
            ),
            onChanged: (v) {
              if (v.trim().isNotEmpty) _pick(v.trim());
            },
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Color(0xFFD34E2F))),
          ],
          const SizedBox(height: 20),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFB53216),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Lưu'),
          ),
        ],
      ),
    );
  }
}
