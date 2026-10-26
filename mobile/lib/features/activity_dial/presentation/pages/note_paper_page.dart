import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/time/vn_time.dart';
import '../activity_dial_controller.dart';

/// Tờ giấy ghi chú cho một bản ghi (NOTE-01). Tự lưu khi rời trang; ghi chú chỉ nằm trên máy.
class NotePaperPage extends ConsumerStatefulWidget {
  const NotePaperPage({super.key, required this.logId});

  final String logId;

  @override
  ConsumerState<NotePaperPage> createState() => _NotePaperPageState();
}

class _NotePaperPageState extends ConsumerState<NotePaperPage> {
  static const _lineHeight = 32.0;
  static const _fontSize = 17.0;
  static const _paper = Color(0xFFFFFBEF);
  static const _ink = Color(0xFF2E241F);

  late final TextEditingController _text;
  late final ActivityDialController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ref.read(activityDialControllerProvider.notifier);
    final log = ref
        .read(activityDialControllerProvider)
        .logs
        .where((l) => l.id == widget.logId)
        .firstOrNull;
    _text = TextEditingController(text: log?.note ?? '');
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _save() => _controller.setNote(widget.logId, _text.text);

  @override
  Widget build(BuildContext context) {
    final log = ref
        .watch(activityDialControllerProvider)
        .logs
        .where((l) => l.id == widget.logId)
        .firstOrNull;
    final when = log == null
        ? ''
        : DateFormat('HH:mm · dd/MM/yyyy').format(VnTime.of(log.occurredAt));

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _save();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFEFE6D8),
        appBar: AppBar(
          backgroundColor: const Color(0xFFEFE6D8),
          title: const Text(
            'Ghi chú',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          actions: [
            TextButton.icon(
              onPressed: () async {
                await _save();
                if (context.mounted) Navigator.pop(context);
              },
              icon: const Icon(Icons.check_rounded),
              label: const Text('Lưu'),
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: _paper,
                borderRadius: BorderRadius.circular(6),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Đầu tờ giấy: sự kiện + thời điểm
                  Padding(
                    padding: const EdgeInsets.fromLTRB(56, 18, 16, 10),
                    child: Row(
                      children: [
                        Text(
                          log?.emoji ?? '',
                          style: const TextStyle(fontSize: 26),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                log?.name ?? '',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: _ink,
                                ),
                              ),
                              Text(
                                when,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: Color(0xFF8A7E74),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Tooltip(
                          message:
                              'Ghi chú chỉ lưu trên máy, bạn bè không thấy',
                          child: Icon(
                            Icons.lock_outline_rounded,
                            size: 18,
                            color: Color(0xFF8A7E74),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Phần giấy kẻ dòng
                  Expanded(
                    child: CustomPaint(
                      painter: const _RuledPaperPainter(
                        lineHeight: _lineHeight,
                        topPadding: 6,
                      ),
                      child: TextField(
                        key: const ValueKey('note-field'),
                        controller: _text,
                        autofocus: true,
                        expands: true,
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                        textAlignVertical: TextAlignVertical.top,
                        cursorColor: const Color(0xFFB53216),
                        style: const TextStyle(
                          fontSize: _fontSize,
                          height: _lineHeight / _fontSize,
                          color: _ink,
                        ),
                        strutStyle: const StrutStyle(
                          fontSize: _fontSize,
                          height: _lineHeight / _fontSize,
                          forceStrutHeight: true,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Viết ghi chú cho sự kiện này…',
                          hintStyle: TextStyle(color: Color(0xFFB8AC9F)),
                          contentPadding: EdgeInsets.fromLTRB(56, 6, 16, 16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Dòng kẻ ngang và đường lề đỏ như giấy viết.
class _RuledPaperPainter extends CustomPainter {
  const _RuledPaperPainter({
    required this.lineHeight,
    required this.topPadding,
  });

  final double lineHeight;
  final double topPadding;

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = const Color(0xFFC9DCEB)
      ..strokeWidth = 1;
    for (var y = topPadding + lineHeight; y < size.height; y += lineHeight) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }
    final margin = Paint()
      ..color = const Color(0xFFE9A3A0)
      ..strokeWidth = 1.5;
    canvas.drawLine(const Offset(44, 0), Offset(44, size.height), margin);
  }

  @override
  bool shouldRepaint(covariant _RuledPaperPainter old) =>
      old.lineHeight != lineHeight || old.topPadding != topPadding;
}
