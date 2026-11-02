import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/activity_event_type.dart';

/// Một nút tròn trên quỹ đạo Dial (Wear OS node)
/// Bao gồm biểu tượng trong vòng tròn màu pastel và nhãn tên bên dưới
class RadialDialNode extends StatefulWidget {
  const RadialDialNode({
    super.key,
    required this.type,
    required this.onTap,
    this.iconSize = 19.0,
    this.circleRadius = 19.0,
  });

  final ActivityEventType type;
  final VoidCallback onTap;
  final double iconSize;
  final double circleRadius;

  @override
  State<RadialDialNode> createState() => _RadialDialNodeState();
}

class _RadialDialNodeState extends State<RadialDialNode>
    with TickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _scaleAnimation;

  /// Hiệu ứng sau mỗi lần chấm: vòng màu lan ra và "+1" bay lên rồi mờ dần.
  late final AnimationController _burstController;

  /// Rung rung định kỳ khi nghỉ: mỗi chu kỳ icon lắc nhẹ vài nhịp rồi đứng yên.
  /// Mọi nút chung một chu kỳ nhưng lệch pha theo từng loại để không rung cùng lúc.
  late final AnimationController _idleController;

  /// Chu kỳ chung của cả vòng Dial. Mỗi nút chỉ chạy đoạn đầu (rung + gợn sóng, 36% chu kỳ)
  /// sau độ lệch tối đa [_idleMaxOffset], nên cuối mỗi chu kỳ cả vòng nghỉ ~1,7 giây không vẽ
  /// khung hình nào (đỡ tốn pin, `pumpAndSettle` trong test vẫn dừng được).
  static const _idleCycle = Duration(milliseconds: 5000);
  static const _idleMaxOffset = Duration(milliseconds: 1500);
  static const _idleActiveEnd = 0.36;
  Timer? _idleTimer;

  @override
  void initState() {
    super.initState();
    final seed = widget.type.id.hashCode.abs();
    const cycle = _idleCycle;
    _idleController = AnimationController(vsync: this, duration: cycle)
      ..value = _idleActiveEnd;
    _idleTimer = Timer(_idleMaxOffset * ((seed % 1000) / 1000), () {
      _playIdle();
      _idleTimer = Timer.periodic(cycle, (_) => _playIdle());
    });
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.82).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
    _burstController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
  }

  void _playIdle() {
    if (!mounted || MediaQuery.maybeDisableAnimationsOf(context) == true) {
      return;
    }
    _idleController
      ..value = 0
      ..animateTo(_idleActiveEnd);
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    _idleController.dispose();
    _burstController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    _animController.forward().then((_) {
      _animController.reverse();
    });
    _burstController.forward(from: 0);
    widget.onTap();
  }

  /// Góc lắc (radian) và độ phóng của icon tại thời điểm hiện tại.
  ({double angle, double scale}) _wiggle(bool reduceMotion) {
    var angle = 0.0;
    var scale = 1.0;

    // Rung khi nghỉ: 22% đầu chu kỳ lắc 3 nhịp tắt dần (~±6°), còn lại đứng yên.
    final idle = _idleController.value;
    if (!reduceMotion && idle < 0.22) {
      final p = idle / 0.22;
      angle += 0.10 * math.sin(p * 2 * math.pi * 3) * (1 - p);
      scale += 0.06 * math.sin(p * math.pi);
    }

    // Rung mạnh khi chấm: 4 nhịp tắt dần (~±16°).
    final t = _burstController.value;
    if (t > 0 && t < 1) {
      final decay = (1 - t) * (1 - t);
      angle += 0.28 * math.sin(t * 2 * math.pi * 4) * decay;
    }
    return (angle: angle, scale: scale);
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _handleTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Vòng tròn chứa icon màu pastel, cùng hiệu ứng sau mỗi lần chấm
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                _RippleRings(
                  idle: _idleController,
                  tap: _burstController,
                  size: widget.circleRadius * 2,
                  color: widget.type.accentColor,
                  enabled: !reduceMotion,
                ),
                AnimatedBuilder(
                  animation: Listenable.merge([
                    _idleController,
                    _burstController,
                  ]),
                  builder: (context, child) {
                    final w = _wiggle(reduceMotion);
                    return Transform.rotate(
                      angle: w.angle,
                      child: Transform.scale(scale: w.scale, child: child),
                    );
                  },
                  child: Container(
                    width: widget.circleRadius * 2,
                    height: widget.circleRadius * 2,
                    decoration: BoxDecoration(
                      color: widget.type.bgColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: widget.type.accentColor.withValues(alpha: 0.35),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: widget.type.accentColor.withValues(
                            alpha: 0.12,
                          ),
                          blurRadius: 4,
                          offset: const Offset(0, 1.5),
                        ),
                      ],
                    ),
                    child: Center(
                      child: widget.type.icon != null
                          ? Icon(
                              widget.type.icon,
                              size: widget.iconSize,
                              color: widget.type.accentColor,
                            )
                          : Text(
                              widget.type.emoji,
                              style: TextStyle(fontSize: widget.iconSize),
                            ),
                    ),
                  ),
                ),
                _PlusOne(
                  animation: _burstController,
                  color: widget.type.accentColor,
                  lift: widget.circleRadius * 1.9,
                ),
              ],
            ),
            const SizedBox(height: 2.5),
            // Nhãn chữ bên dưới
            SizedBox(
              width: 58,
              child: Text(
                widget.type.name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10.0,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                  color: Color(0xFF3B322D),
                  height: 1.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Gợn sóng lan ra quanh nút như giọt nước rơi xuống mặt hồ: 2 vòng mảnh nở ra từ viền rồi mờ dần.
/// Khi nghỉ: gợn nhỏ (tới 1,65 lần nút) theo nhịp rung định kỳ.
/// Khi chấm: gợn rộng hơn (tới 2,1 lần nút) và đậm hơn.
class _RippleRings extends AnimatedWidget {
  _RippleRings({
    required this.idle,
    required this.tap,
    required this.size,
    required this.color,
    required this.enabled,
  }) : super(listenable: Listenable.merge([idle, tap]));

  final AnimationController idle;
  final AnimationController tap;
  final double size;
  final Color color;

  /// `false` khi máy bật giảm chuyển động: bỏ gợn khi nghỉ, vẫn giữ gợn khi chấm.
  final bool enabled;

  /// Vòng thứ 2 xuất phát trễ hơn vòng đầu.
  static const _idleRingDelay = Duration(milliseconds: 280);
  static const _tapRingDelay = 0.19;

  @override
  Widget build(BuildContext context) {
    final rings = <({double scale, double opacity})>[];

    if (enabled) {
      final cycleMs = idle.duration!.inMilliseconds;
      for (var i = 0; i < 2; i++) {
        final start = i * _idleRingDelay.inMilliseconds / cycleMs;
        final p = (idle.value - start) / 0.26;
        if (p > 0 && p < 1) {
          final e = Curves.easeOut.transform(p);
          rings.add((scale: 1 + 0.65 * e, opacity: 0.55 * (1 - e)));
        }
      }
    }

    final t = tap.value;
    for (var i = 0; i < 2; i++) {
      final q = (t - i * _tapRingDelay) / (1 - _tapRingDelay);
      if (q > 0 && q < 1) {
        final e = Curves.easeOut.transform(q);
        rings.add((scale: 1 + 1.1 * e, opacity: 0.8 * (1 - e)));
      }
    }

    if (rings.isEmpty) return const SizedBox.shrink();
    return IgnorePointer(
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            for (final r in rings)
              Positioned.fill(
                child: Transform.scale(
                  scale: r.scale,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: color.withValues(alpha: r.opacity),
                        width: 1.4 / r.scale,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// "+1" bay lên phía trên nút rồi mờ dần.
class _PlusOne extends AnimatedWidget {
  const _PlusOne({
    required Animation<double> animation,
    required this.color,
    required this.lift,
  }) : super(listenable: animation);

  final Color color;
  final double lift;

  @override
  Widget build(BuildContext context) {
    final t = (listenable as Animation<double>).value;
    if (t == 0 || t == 1) return const SizedBox.shrink();
    return Positioned(
      top: -lift * Curves.easeOutCubic.transform(t),
      child: IgnorePointer(
        child: Opacity(
          opacity: t < 0.5 ? 1 : (1 - t) * 2,
          child: Text(
            '+1',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}
