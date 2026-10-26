import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/activity_event_type.dart';
import '../../domain/emoji_catalog.dart';
import '../activity_dial_controller.dart';

/// Cài đặt → Loại sự kiện: xem và tạo loại sự kiện của riêng mình (LOG-01, LOG-02, LOG-05).
/// Loại đã tạo không sửa, không sắp xếp; hiển thị ở hàng "Sự kiện của bạn" trên trang chủ.
class EventTypesPage extends ConsumerWidget {
  const EventTypesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(activityDialControllerProvider);
    final custom = state.customTypes;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF6F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF6F0),
        title: const Text(
          'Loại sự kiện',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFB53216),
        foregroundColor: Colors.white,
        onPressed: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const AddEventTypeSheet(),
        ),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Thêm loại sự kiện'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          Text(
            '${state.dialTypes.length} loại mặc định trên vòng tròn, ${custom.length} loại của bạn.',
            style: const TextStyle(color: Color(0xFF7E7369)),
          ),
          const SizedBox(height: 4),
          const Text(
            'Loại đã tạo không sửa và không sắp xếp lại được.',
            style: TextStyle(fontSize: 12, color: Color(0xFF948A80)),
          ),
          const SizedBox(height: 16),
          if (custom.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Text(
                'Chưa có loại sự kiện nào của bạn.\nBấm "Thêm loại sự kiện" để tạo.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF948A80), height: 1.4),
              ),
            )
          else
            for (final type in custom) _EventTypeTile(type: type),
        ],
      ),
    );
  }
}

class _EventTypeTile extends StatelessWidget {
  const _EventTypeTile({required this.type});

  final ActivityEventType type;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F4EB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDE4D6)),
      ),
      child: Row(
        children: [
          Text(type.emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              type.name,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bảng tạo loại sự kiện: chọn emoji (tên tự điền theo emoji, LOG-02) hoặc nhập emoji khác.
class AddEventTypeSheet extends ConsumerStatefulWidget {
  const AddEventTypeSheet({super.key});

  @override
  ConsumerState<AddEventTypeSheet> createState() => _AddEventTypeSheetState();
}

class _AddEventTypeSheetState extends ConsumerState<AddEventTypeSheet> {
  final _emoji = TextEditingController();
  final _name = TextEditingController();

  /// Tên đã được người dùng tự sửa thì không ghi đè khi đổi emoji nữa.
  bool _nameEdited = false;
  String? _error;

  @override
  void dispose() {
    _emoji.dispose();
    _name.dispose();
    super.dispose();
  }

  void _pickEmoji(String emoji) {
    _emoji.text = emoji;
    _onEmojiChanged(emoji);
  }

  void _onEmojiChanged(String emoji) {
    setState(() {
      final defaultName = emojiCatalog[emoji.trim()];
      if (!_nameEdited && defaultName != null) _name.text = defaultName;
      _error = null;
    });
  }

  Future<void> _save() async {
    try {
      final type = await ref
          .read(activityDialControllerProvider.notifier)
          .addEventType(emoji: _emoji.text, name: _name.text);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã thêm ${type.emoji} ${type.name}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on ArgumentError catch (e) {
      setState(() => _error = '${e.message}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFFFDF9),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thêm loại sự kiện',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            const Text(
              'Chọn emoji',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 168,
              // Ô cố định ~48px để màn hình rộng (Web) không phóng to emoji và che bớt lưới.
              child: GridView.extent(
                maxCrossAxisExtent: 48,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
                children: [
                  for (final emoji in emojiCatalog.keys)
                    InkWell(
                      key: ValueKey('emoji-$emoji'),
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => _pickEmoji(emoji),
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _emoji.text == emoji
                              ? const Color(0xFFFDEEE8)
                              : null,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 22),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                SizedBox(
                  width: 96,
                  child: TextField(
                    key: const ValueKey('emoji-field'),
                    controller: _emoji,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 22),
                    decoration: const InputDecoration(
                      labelText: 'Emoji',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: _onEmojiChanged,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    key: const ValueKey('name-field'),
                    controller: _name,
                    maxLength: 50,
                    decoration: const InputDecoration(
                      labelText: 'Tên sự kiện',
                      border: OutlineInputBorder(),
                      counterText: '',
                    ),
                    onChanged: (_) => _nameEdited = true,
                  ),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: Color(0xFFD34E2F))),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFB53216),
                ),
                onPressed: _save,
                child: const Text('Lưu'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
