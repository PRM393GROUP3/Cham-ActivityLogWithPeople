import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/emoji_catalog.dart';
import '../activity_dial_controller.dart';

/// Mở thẻ "Hoạt động mới" từ nút + ở tâm vòng Dial: nền mờ đi, thẻ hiện giữa màn hình.
Future<void> showAddActivityDialog(BuildContext context) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Huỷ',
    barrierColor: const Color(0x73221A16),
    transitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (_, _, _) => const AddActivityDialog(),
    transitionBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeIn,
      );
      return BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 5 * animation.value,
          sigmaY: 5 * animation.value,
        ),
        child: FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween(begin: 0.9, end: 1.0).animate(curved),
            child: child,
          ),
        ),
      );
    },
  );
}

/// Thẻ thêm hoạt động tự tạo: lưới emoji lướt dọc ngay trong thẻ, ô tên (tự điền theo emoji,
/// LOG-02), nút X huỷ và V xác nhận. Không có ô icon lớn để chừa chỗ cho bàn phím.
class AddActivityDialog extends ConsumerStatefulWidget {
  const AddActivityDialog({super.key});

  @override
  ConsumerState<AddActivityDialog> createState() => _AddActivityDialogState();
}

class _AddActivityDialogState extends ConsumerState<AddActivityDialog> {
  final _name = TextEditingController();
  String? _emoji;

  /// Người dùng đã tự gõ tên thì không ghi đè khi đổi emoji nữa.
  bool _nameEdited = false;
  bool _saving = false;
  String? _error;

  static const _coral = Color(0xFFFF694A);
  static const _ink = Color(0xFF2B221D);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  bool get _canSave =>
      _emoji != null && _name.text.trim().isNotEmpty && !_saving;

  void _pickEmoji(String emoji) {
    HapticFeedback.selectionClick();
    setState(() {
      _emoji = emoji;
      final defaultName = emojiCatalog[emoji];
      if (!_nameEdited && defaultName != null) _name.text = defaultName;
      _error = null;
    });
  }

  Future<void> _save() async {
    if (!_canSave) return;
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final type = await ref
          .read(activityDialControllerProvider.notifier)
          .addEventType(emoji: _emoji!, name: _name.text);
      if (!mounted) return;
      Navigator.pop(context);
      messenger.showSnackBar(
        SnackBar(
          content: Text('Đã thêm ${type.emoji} ${type.name}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on ArgumentError catch (e) {
      setState(() {
        _saving = false;
        _error = '${e.message}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.of(context).viewInsets.bottom;
    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: keyboard),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          child: Material(
            color: const Color(0xFFFDF8F3),
            borderRadius: BorderRadius.circular(26),
            elevation: 12,
            shadowColor: Colors.black38,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Hoạt động mới',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _EmojiGrid(selected: _emoji, onPick: _pickEmoji),
                    const SizedBox(height: 12),
                    TextField(
                      key: const ValueKey('add-activity-name'),
                      controller: _name,
                      maxLength: 50,
                      textInputAction: TextInputAction.done,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _ink,
                      ),
                      decoration: InputDecoration(
                        hintText: _emoji == null
                            ? 'Chọn emoji rồi đặt tên'
                            : 'Tên hoạt động',
                        counterText: '',
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: _emoji == null
                            ? null
                            : Padding(
                                padding: const EdgeInsets.only(
                                  left: 12,
                                  right: 6,
                                ),
                                child: Text(
                                  _emoji!,
                                  style: const TextStyle(fontSize: 22),
                                ),
                              ),
                        prefixIconConstraints: const BoxConstraints(
                          minWidth: 0,
                          minHeight: 0,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFFEADBD0),
                            width: 1.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFFFF8A6B),
                            width: 1.5,
                          ),
                        ),
                      ),
                      onChanged: (_) => setState(() {
                        _nameEdited = true;
                        _error = null;
                      }),
                      onSubmitted: (_) => _save(),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFFD34E2F),
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _RoundButton(
                          key: const ValueKey('add-activity-cancel'),
                          icon: Icons.close_rounded,
                          tooltip: 'Huỷ',
                          background: Colors.white,
                          foreground: const Color(0xFF7A6C63),
                          onTap: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 24),
                        _RoundButton(
                          key: const ValueKey('add-activity-confirm'),
                          icon: Icons.check_rounded,
                          tooltip: 'Thêm hoạt động',
                          background: _coral,
                          foreground: Colors.white,
                          onTap: _canSave ? _save : null,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Lưới emoji cao cố định ~3,5 hàng, lướt dọc ngay trong thẻ để xem hết [pickerEmojis].
class _EmojiGrid extends StatelessWidget {
  const _EmojiGrid({required this.selected, required this.onPick});

  final String? selected;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 168,
      decoration: BoxDecoration(
        color: const Color(0xFFF6ECE4),
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 46,
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
        ),
        itemCount: pickerEmojis.length,
        itemBuilder: (context, i) {
          final emoji = pickerEmojis[i];
          final isSelected = emoji == selected;
          return GestureDetector(
            key: ValueKey('add-activity-emoji-$emoji'),
            onTap: () => onPick(emoji),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFFFE3D6) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFFF8A6B)
                      : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Text(emoji, style: const TextStyle(fontSize: 21)),
            ),
          );
        },
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final Color background;
  final Color foreground;

  /// `null` = vô hiệu (mờ đi).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Tooltip(
      message: tooltip,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: enabled ? 1 : 0.4,
        child: Material(
          color: background,
          shape: const CircleBorder(),
          elevation: enabled ? 4 : 0,
          shadowColor: background == Colors.white
              ? Colors.black26
              : background.withValues(alpha: 0.5),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: 52,
              height: 52,
              child: Icon(icon, size: 28, color: foreground),
            ),
          ),
        ),
      ),
    );
  }
}
