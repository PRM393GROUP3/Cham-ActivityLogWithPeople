import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/avatar.dart';
import '../account_controller.dart';
import '../widgets/user_avatar.dart';

/// Đặt tên hiển thị và avatar emoji — bạn bè thấy trong danh sách bạn bè, feed và reaction.
/// Lưu lên server nên cần mạng; lần đầu sẽ tự tạo tài khoản ẩn danh.
class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _name = TextEditingController();
  final _customEmoji = TextEditingController();
  String? _emoji;
  bool _loaded = false;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _customEmoji.dispose();
    super.dispose();
  }

  void _pick(String? emoji) => setState(() {
        _emoji = emoji;
        _error = null;
      });

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) return setState(() => _error = 'Hãy nhập tên hiển thị.');
    if (name.characters.length > 50) return setState(() => _error = 'Tên tối đa 50 ký tự.');
    if (_emoji != null && !isSingleEmoji(_emoji!)) {
      return setState(() => _error = 'Avatar phải là đúng một emoji.');
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(accountControllerProvider.notifier).updateProfile(displayName: name, avatarEmoji: _emoji?.trim());
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã lưu hồ sơ'), behavior: SnackBarBehavior.floating),
      );
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
      _name.text = account?.displayName ?? AccountController.defaultDisplayName;
      _emoji = account?.avatarEmoji;
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
          Center(child: UserAvatar(name: name, emoji: _emoji, radius: 44)),
          const SizedBox(height: 8),
          const Text(
            'Bạn bè thấy tên và avatar này trong danh sách bạn bè và feed.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: Color(0xFF8A7E74)),
          ),
          const SizedBox(height: 20),
          TextField(
            key: const ValueKey('profile-name'),
            controller: _name,
            maxLength: 50,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Tên hiển thị', border: OutlineInputBorder()),
            onChanged: (_) => setState(() => _error = null),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Expanded(child: Text('Avatar', style: TextStyle(fontWeight: FontWeight.w800))),
              TextButton.icon(
                onPressed: _emoji == null ? null : () => _pick(null),
                icon: const Icon(Icons.close_rounded, size: 18),
                label: const Text('Bỏ avatar'),
              ),
            ],
          ),
          GridView.extent(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            maxCrossAxisExtent: 52,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            children: [
              for (final e in avatarEmojiChoices)
                InkWell(
                  key: ValueKey('avatar-$e'),
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _pick(e),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _emoji == e ? const Color(0xFFFDEEE8) : null,
                      border: _emoji == e ? Border.all(color: const Color(0xFFB53216), width: 1.5) : null,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(e, style: const TextStyle(fontSize: 24)),
                  ),
                ),
            ],
          ),
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
