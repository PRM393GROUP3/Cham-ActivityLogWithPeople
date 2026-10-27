import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/activity_event_type.dart';
import '../../domain/dial_layout.dart';
import '../../domain/emoji_catalog.dart';
import '../activity_dial_controller.dart';

/// Cài đặt → Loại sự kiện (LOG-05): thêm, sửa, xoá và kéo thả sắp xếp mọi loại sự kiện,
/// kể cả 19 loại mặc định. Thứ tự quyết định vị trí trên vòng Dial; sửa / xoá không đổi lịch sử.
class EventTypesPage extends ConsumerWidget {
  const EventTypesPage({super.key});

  void _openSheet(BuildContext context, [ActivityEventType? editing]) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EventTypeSheet(editing: editing),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, ActivityEventType type) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Xoá ${type.emoji} ${type.name}?'),
        content: const Text('Nút này biến khỏi trang chủ. Các lần chấm trước đó vẫn giữ trong lịch sử.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFD34E2F)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xoá'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await ref.read(activityDialControllerProvider.notifier).deleteEventType(type.id);
    } on ArgumentError catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${e.message}'), behavior: SnackBarBehavior.floating),
      );
    }
  }

  static String _positionLabel(int index, int count) =>
      const {1: 'Vòng trong', 2: 'Vòng giữa', 3: 'Vòng ngoài'}[dialRingOf(index, count)]!;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final types = ref.watch(activityDialControllerProvider).eventTypes;
    final controller = ref.read(activityDialControllerProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF6F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF6F0),
        title: const Text('Loại sự kiện', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFB53216),
        foregroundColor: Colors.white,
        onPressed: () => _openSheet(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Thêm loại sự kiện'),
      ),
      body: ReorderableListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
        buildDefaultDragHandles: false,
        header: const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text(
            'Kéo ⠿ để đổi thứ tự: các loại đầu danh sách ở vòng trong, rồi vòng giữa, rồi vòng ngoài '
            '(6 / 6 / 7 với 19 loại; thêm loại thì vòng ngoài và vòng giữa nhận thêm). Tối đa '
            '$maxEventTypes loại. Sửa hoặc xoá không ảnh hưởng các lần chấm trước đó.',
            style: TextStyle(fontSize: 12.5, color: Color(0xFF7E7369), height: 1.35),
          ),
        ),
        itemCount: types.length,
        onReorderItem: controller.reorderEventTypes,
        itemBuilder: (context, index) {
          final type = types[index];
          return _EventTypeTile(
            key: ValueKey(type.id),
            type: type,
            position: _positionLabel(index, types.length),
            dragHandle: ReorderableDragStartListener(
              index: index,
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.drag_indicator_rounded, color: Color(0xFFA89C91)),
              ),
            ),
            onEdit: () => _openSheet(context, type),
            onDelete: () => _confirmDelete(context, ref, type),
          );
        },
      ),
    );
  }
}

class _EventTypeTile extends StatelessWidget {
  const _EventTypeTile({
    super.key,
    required this.type,
    required this.position,
    required this.dragHandle,
    required this.onEdit,
    required this.onDelete,
  });

  final ActivityEventType type;
  final String position;
  final Widget dragHandle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F4EB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDE4D6)),
      ),
      child: Row(
        children: [
          dragHandle,
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: type.bgColor, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: type.icon != null
                ? Icon(type.icon, size: 19, color: type.accentColor)
                : Text(type.emoji, style: const TextStyle(fontSize: 19)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${type.emoji} ${type.name}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                Text(position, style: const TextStyle(fontSize: 11.5, color: Color(0xFF8A7E74))),
              ],
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'Sửa ${type.name}',
            icon: const Icon(Icons.edit_outlined, size: 20, color: Color(0xFF6E6259)),
            onPressed: onEdit,
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'Xoá ${type.name}',
            icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Color(0xFFD34E2F)),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

/// Bảng thêm / sửa loại sự kiện: chọn emoji (tên tự điền theo emoji, LOG-02) hoặc nhập emoji khác.
class EventTypeSheet extends ConsumerStatefulWidget {
  const EventTypeSheet({super.key, this.editing});

  /// `null` = thêm mới.
  final ActivityEventType? editing;

  @override
  ConsumerState<EventTypeSheet> createState() => _EventTypeSheetState();
}

class _EventTypeSheetState extends ConsumerState<EventTypeSheet> {
  late final _emoji = TextEditingController(text: widget.editing?.emoji);
  late final _name = TextEditingController(text: widget.editing?.name);

  /// Tên đã có (đang sửa) hoặc người dùng tự gõ thì không ghi đè khi đổi emoji nữa.
  late bool _nameEdited = widget.editing != null;
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
    final controller = ref.read(activityDialControllerProvider.notifier);
    try {
      final editing = widget.editing;
      final String message;
      if (editing == null) {
        final type = await controller.addEventType(emoji: _emoji.text, name: _name.text);
        message = 'Đã thêm ${type.emoji} ${type.name}';
      } else {
        await controller.updateEventType(editing.id, emoji: _emoji.text, name: _name.text);
        message = 'Đã lưu thay đổi';
      }
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
    } on ArgumentError catch (e) {
      setState(() => _error = '${e.message}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
            Text(
              widget.editing == null ? 'Thêm loại sự kiện' : 'Sửa loại sự kiện',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            const Text('Chọn emoji', style: TextStyle(fontWeight: FontWeight.w700)),
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
                          color: _emoji.text == emoji ? const Color(0xFFFDEEE8) : null,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(emoji, style: const TextStyle(fontSize: 22)),
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
                    decoration: const InputDecoration(labelText: 'Emoji', border: OutlineInputBorder()),
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
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFFB53216)),
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
