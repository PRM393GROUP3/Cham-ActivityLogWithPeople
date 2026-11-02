import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cham/features/activity_dial/presentation/pages/activity_dial_page.dart';
import 'package:cham/features/history/presentation/pages/history_page.dart';
import 'package:cham/features/social/presentation/pages/feed_page.dart';
import 'package:cham/features/stats/presentation/pages/stats_page.dart';

/// Lật trang nhẹ tay: thả tay khi vẫn đang di chuyển (dù chậm) là sang trang theo hướng đó,
/// chỉ bật về khi mới kéo rất ít; lò xo snap nhanh hơn mặc định.
class _LightPageScrollPhysics extends PageScrollPhysics {
  const _LightPageScrollPhysics({super.parent});

  /// Kéo chưa tới phần này của một trang (và không hất mạnh) thì bật về trang cũ.
  static const _minPageFraction = 0.12;
  static const _flickVelocity = 400.0;

  @override
  _LightPageScrollPhysics applyTo(ScrollPhysics? ancestor) =>
      _LightPageScrollPhysics(parent: buildParent(ancestor));

  // Mặc định 50: thả tay chậm hơn mức này thì vận tốc bị coi là 0 và trang bật về.
  @override
  double get minFlingVelocity => 8;

  @override
  SpringDescription get spring =>
      SpringDescription.withDampingRatio(mass: 0.5, stiffness: 220, ratio: 1.0);

  @override
  Simulation? createBallisticSimulation(ScrollMetrics position, double velocity) {
    if ((velocity <= 0 && position.pixels <= position.minScrollExtent) ||
        (velocity >= 0 && position.pixels >= position.maxScrollExtent)) {
      return super.createBallisticSimulation(position, velocity);
    }
    final size = position.viewportDimension;
    final page = position.pixels / size;
    final nearest = page.roundToDouble();
    final tolerance = toleranceFor(position);
    final double target;
    if ((page - nearest).abs() < _minPageFraction && velocity.abs() < _flickVelocity) {
      target = nearest;
    } else if (velocity > tolerance.velocity) {
      target = page.ceilToDouble();
    } else if (velocity < -tolerance.velocity) {
      target = page.floorToDouble();
    } else {
      target = nearest;
    }
    final pixels = (target * size).clamp(position.minScrollExtent, position.maxScrollExtent);
    if ((pixels - position.pixels).abs() < tolerance.distance) return null;
    return ScrollSpringSimulation(spring, position.pixels, pixels, velocity, tolerance: tolerance);
  }
}

/// Các màn trong shell. Trang chủ ở giữa: Phân tích bên trái, Lịch sử bên phải, Bạn bè bên dưới.
enum ShellPane { analytics, home, history, feed }

/// Shell vuốt 4 hướng quanh Trang chủ. Chỉ Trang chủ là ngã tư: từ Bạn bè không vuốt ngang được,
/// từ Phân tích / Lịch sử không vuốt dọc được.
///
/// Nút Back quay lại màn đã xem trước đó (theo thứ tự đã đi), hết lịch sử thì về Trang chủ; ở
/// Trang chủ phải bấm Back hai lần liền để thoát app.
class MainShellPage extends StatefulWidget {
  const MainShellPage({
    super.key,
    this.initialPane = ShellPane.home,
  });

  final ShellPane initialPane;

  @override
  State<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends State<MainShellPage> {
  static const _duration = Duration(milliseconds: 260);
  static const _physics = _LightPageScrollPhysics(parent: ClampingScrollPhysics());
  static const _curve = Curves.easeOutCubic;
  static const _maxHistory = 30;
  static const _exitWindow = Duration(seconds: 2);

  late ShellPane _pane = widget.initialPane;
  late final PageController _h = PageController(initialPage: _column(widget.initialPane));
  late final PageController _v = PageController(initialPage: widget.initialPane == ShellPane.feed ? 1 : 0);

  /// Các màn đã đi qua, cũ nhất trước; Back lấy dần từ cuối.
  final List<ShellPane> _history = [];

  /// Đang chuyển màn bằng code: bỏ qua các điểm dừng giữa chừng của PageView.
  bool _navigating = false;

  DateTime? _lastBackAtHome;
  bool _showExitHint = false;
  Timer? _exitHintTimer;

  static int _column(ShellPane pane) => switch (pane) {
        ShellPane.analytics => 0,
        ShellPane.home || ShellPane.feed => 1,
        ShellPane.history => 2,
      };

  @override
  void dispose() {
    _exitHintTimer?.cancel();
    _h.dispose();
    _v.dispose();
    super.dispose();
  }

  void _setPane(ShellPane pane, {bool record = true}) {
    if (pane == _pane) return;
    if (record) {
      _history.add(_pane);
      if (_history.length > _maxHistory) _history.removeAt(0);
    }
    setState(() => _pane = pane);
  }

  /// Màn hiện tại sau khi người dùng vuốt xong (chỉ tính lúc PageView dừng hẳn).
  ShellPane _settledPane() {
    final column = _h.hasClients ? _h.page!.round() : _column(_pane);
    if (column == 0) return ShellPane.analytics;
    if (column == 2) return ShellPane.history;
    final row = _v.hasClients ? _v.page!.round() : 0;
    return row == 1 ? ShellPane.feed : ShellPane.home;
  }

  bool _onScrollEnd(ScrollEndNotification n) {
    // depth 0: chỉ PageView ngay bên dưới listener, không phải danh sách bên trong từng màn.
    if (n.depth == 0 && !_navigating) _setPane(_settledPane());
    return false;
  }

  Future<void> _goTo(ShellPane pane, {bool record = true}) async {
    _navigating = true;
    try {
      final column = _column(pane);
      final row = pane == ShellPane.feed ? 1 : 0;
      // Rời Bạn bè sang ngang: lên Trang chủ trước.
      if (_v.hasClients && _v.page!.round() != 0 && column != 1) {
        await _v.animateToPage(0, duration: _duration, curve: _curve);
      }
      if (_h.hasClients && _h.page!.round() != column) {
        await _h.animateToPage(column, duration: _duration, curve: _curve);
      }
      if (row == 1) await WidgetsBinding.instance.endOfFrame;
      if (_v.hasClients && _v.page!.round() != row) {
        await _v.animateToPage(row, duration: _duration, curve: _curve);
      }
    } finally {
      _navigating = false;
    }
    if (mounted) _setPane(pane, record: record);
  }

  void _onBack() {
    if (_history.isNotEmpty) {
      _goTo(_history.removeLast(), record: false);
      return;
    }
    if (_pane != ShellPane.home) {
      _goTo(ShellPane.home, record: false);
      return;
    }
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }
    final now = DateTime.now();
    if (_lastBackAtHome != null && now.difference(_lastBackAtHome!) < _exitWindow) {
      SystemNavigator.pop();
      return;
    }
    _lastBackAtHome = now;
    _exitHintTimer?.cancel();
    setState(() => _showExitHint = true);
    _exitHintTimer = Timer(_exitWindow, () {
      if (mounted) setState(() => _showExitHint = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final home = NotificationListener<ScrollEndNotification>(
      onNotification: _onScrollEnd,
      child: PageView(
        controller: _v,
        scrollDirection: Axis.vertical,
        physics: _physics,
        children: [
          ActivityDialPage(
            onNavigateToFeed: () => _goTo(ShellPane.feed),
            onNavigateToAnalytics: () => _goTo(ShellPane.analytics),
            onNavigateToHistory: () => _goTo(ShellPane.history),
          ),
          FeedPage(onNavigateToHome: () => _goTo(ShellPane.home)),
        ],
      ),
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onBack();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFAF6F0),
        body: Stack(
          children: [
            NotificationListener<ScrollEndNotification>(
              onNotification: _onScrollEnd,
              child: PageView(
                controller: _h,
                // Dựng sẵn Phân tích / Lịch sử bên cạnh để lúc vuốt không phải chờ build.
                allowImplicitScrolling: true,
                physics: _pane == ShellPane.feed ? const NeverScrollableScrollPhysics() : _physics,
                children: [
                  StatsPage(onNavigateToHome: () => _goTo(ShellPane.home)),
                  home,
                  HistoryPage(onNavigateToHome: () => _goTo(ShellPane.home)),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 64,
              child: IgnorePointer(
                child: AnimatedOpacity(
                  opacity: _showExitHint ? 1 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xCC2B221D),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Text(
                        'Bấm lần nữa để thoát',
                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
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
