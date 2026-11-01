import 'package:flutter/material.dart';

/// Thả cảm xúc: emoji phóng to và bay lên từ nút vừa chạm rồi mờ dần (~0,9 giây).
/// Không làm gì nếu không có [Overlay] phía trên [context].
void showReactionBurst(BuildContext context, String emoji) {
  final overlay = Overlay.maybeOf(context);
  final box = context.findRenderObject() as RenderBox?;
  if (overlay == null || box == null || !box.hasSize) return;
  final origin = box.localToGlobal(box.size.center(Offset.zero), ancestor: overlay.context.findRenderObject());

  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => Positioned(
      left: origin.dx - 40,
      top: origin.dy - 40,
      // Overlay không có Material phía trên: thiếu nó chữ bị gạch chân vàng (kiểu chữ debug).
      child: Material(
        type: MaterialType.transparency,
        child: IgnorePointer(
          child: _Burst(emoji: emoji, onDone: () => entry.remove()),
        ),
      ),
    ),
  );
  overlay.insert(entry);
}

class _Burst extends StatelessWidget {
  const _Burst({required this.emoji, required this.onDone});

  final String emoji;
  final VoidCallback onDone;

  static const rise = 110.0;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      onEnd: onDone,
      builder: (context, t, child) => Opacity(
        opacity: t < 0.6 ? 1 : (1 - t) / 0.4,
        child: Transform.translate(
          offset: Offset(0, -rise * t),
          child: Transform.scale(scale: 1 + 1.4 * Curves.elasticOut.transform(t.clamp(0, 1)), child: child),
        ),
      ),
      child: SizedBox(
        width: 80,
        height: 80,
        child: Center(child: Text(emoji, style: const TextStyle(fontSize: 26))),
      ),
    );
  }
}
