import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../activity_dial/presentation/widgets/center_cham_hub.dart';

/// Màn mở app: chấm đỏ "Chấm" hiện ngay frame đầu trên nền kem (trùng màu splash Android), rồi
/// trượt về đúng nút + của vòng Dial trong lúc Trang chủ mở ra thành vòng tròn từ nút đó.
/// Chỉ chạy một lần mỗi lần mở lạnh; quay lại từ nền không chạy lại.
class StartupIntro extends StatefulWidget {
  const StartupIntro({super.key, required this.toDial, required this.child});

  /// `true`: màn bên dưới là Trang chủ, chờ nút + có vị trí rồi thu chấm về đó.
  /// `false`: màn chào lần đầu, chỉ mờ dần. `null`: chưa biết.
  final bool? toDial;
  final Widget child;

  static const background = Color(0xFFFAF6F0);

  @override
  State<StartupIntro> createState() => _StartupIntroState();
}

class _StartupIntroState extends State<StartupIntro> with TickerProviderStateMixin {
  static const _dotDiameter = 72.0;

  /// Trang chủ chậm quá mức này (máy yếu, dữ liệu lỗi) thì thôi chờ, mờ dần cho vào luôn.
  static const _maxWait = Duration(milliseconds: 2500);

  late final AnimationController _in = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  )..addStatusListener((_) => _tryExit());
  late final AnimationController _out = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 640),
  )..addStatusListener((status) {
      if (status == AnimationStatus.completed) setState(() => _done = true);
    });

  final _overlayKey = GlobalKey();
  Timer? _giveUp;
  bool _timedOut = false;
  bool _done = false;

  /// Nút + theo toạ độ của lớp phủ; `null` khi không thu về nút (màn chào, quá giờ chờ).
  Rect? _target;

  @override
  void initState() {
    super.initState();
    _giveUp = Timer(_maxWait, () {
      _timedOut = true;
      _tryExit();
    });
    centerHubRect.addListener(_tryExit);
    _in.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _in.duration = Duration.zero;
      _out.duration = const Duration(milliseconds: 200);
    }
  }

  @override
  void didUpdateWidget(StartupIntro oldWidget) {
    super.didUpdateWidget(oldWidget);
    _tryExit();
  }

  @override
  void dispose() {
    _giveUp?.cancel();
    centerHubRect.removeListener(_tryExit);
    _in.dispose();
    _out.dispose();
    super.dispose();
  }

  void _tryExit() {
    if (!mounted || _out.isAnimating || _out.isCompleted || !_in.isCompleted) return;
    final toDial = widget.toDial;
    final hub = centerHubRect.value;
    if (!_timedOut && (toDial == null || (toDial && hub == null))) return;

    final box = _overlayKey.currentContext?.findRenderObject() as RenderBox?;
    if (toDial == true && hub != null && box != null && box.hasSize && !MediaQuery.disableAnimationsOf(context)) {
      _target = Rect.fromPoints(box.globalToLocal(hub.topLeft), box.globalToLocal(hub.bottomRight));
    }
    _giveUp?.cancel();
    centerHubRect.removeListener(_tryExit);
    _out.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Luôn ở vị trí đầu: bỏ lớp phủ đi không làm dựng lại màn bên dưới.
        widget.child,
        if (!_done)
          Positioned.fill(
            key: _overlayKey,
            // Chặn chạm trong lúc chuyển cảnh.
            child: AbsorbPointer(
              child: Material(
                type: MaterialType.transparency,
                child: AnimatedBuilder(
                  animation: Listenable.merge([_in, _out]),
                  builder: (context, _) => LayoutBuilder(
                    builder: (context, constraints) => _buildOverlay(constraints.biggest),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildOverlay(Size size) {
    final appear = Curves.easeOutCubic.transform(_in.value);
    final t = _out.value;
    final start = Rect.fromCircle(center: Offset(size.width / 2, size.height * 0.46), radius: _dotDiameter / 2);
    final target = _target;

    double phase(double from, double to, Curve curve) => curve.transform(((t - from) / (to - from)).clamp(0.0, 1.0));

    if (target == null) {
      // Màn chào hoặc quá giờ: mọi thứ mờ dần, chấm hơi thu nhỏ.
      final fade = phase(0, 1, Curves.easeOut);
      return Opacity(
        opacity: 1 - fade,
        child: ColoredBox(
          color: StartupIntro.background,
          child: Stack(children: _logo(start, appear: appear, scale: 1 - 0.15 * fade, wordFade: fade)),
        ),
      );
    }

    // Chấm trượt về nút + trước, vòng tròn mở Trang chủ bắt đầu khi chấm gần tới nơi.
    final move = phase(0, 0.6, Curves.easeInOutCubic);
    final reveal = phase(0.35, 1, Curves.easeInOutCubic);
    final dot = Rect.lerp(start, target, move)!;
    final center = target.center;
    final farthest = [
      Offset.zero,
      Offset(size.width, 0),
      Offset(0, size.height),
      Offset(size.width, size.height),
    ].map((c) => (c - center).distance).reduce(max);

    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _HolePainter(
              center: center,
              radius: target.width / 2 + (farthest - target.width / 2) * reveal,
              open: reveal > 0,
            ),
          ),
        ),
        ..._logo(dot, appear: appear, wordFade: phase(0, 0.3, Curves.easeOut), plus: phase(0.4, 0.75, Curves.easeOut)),
      ],
    );
  }

  /// Chấm đỏ (giống hệt nút + để lúc chạm đích không thấy đổi) và chữ "Chấm" bên dưới.
  List<Widget> _logo(Rect dot, {required double appear, double scale = 1, double wordFade = 0, double plus = 0}) {
    final d = dot.width;
    return [
      Positioned.fromRect(
        rect: dot,
        child: Opacity(
          opacity: appear,
          child: Transform.scale(
            scale: (0.7 + 0.3 * appear) * scale,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFF8A6B), Color(0xFFFF694A)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF694A).withValues(alpha: 0.38),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Opacity(
                opacity: plus,
                child: Icon(Icons.add_rounded, color: Colors.white, size: d * 0.52),
              ),
            ),
          ),
        ),
      ),
      Positioned(
        left: 0,
        right: 0,
        top: dot.bottom + 14 + 8 * wordFade,
        child: Opacity(
          opacity: (appear * (1 - wordFade)).clamp(0.0, 1.0),
          child: const Text(
            'Chấm',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1F1A17),
              letterSpacing: -0.6,
            ),
          ),
        ),
      ),
    ];
  }
}

/// Nền kem phủ kín, khoét một lỗ tròn để Trang chủ lộ ra từ nút +.
class _HolePainter extends CustomPainter {
  const _HolePainter({required this.center, required this.radius, required this.open});

  final Offset center;
  final double radius;
  final bool open;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()..addRect(Offset.zero & size);
    if (open) {
      path
        ..addOval(Rect.fromCircle(center: center, radius: radius))
        ..fillType = PathFillType.evenOdd;
    }
    canvas.drawPath(path, Paint()..color = StartupIntro.background);
  }

  @override
  bool shouldRepaint(_HolePainter old) => old.center != center || old.radius != radius || old.open != open;
}
