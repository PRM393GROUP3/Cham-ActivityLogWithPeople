import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/env.dart';
import '../../account/domain/account.dart';
import '../../account/presentation/account_controller.dart';
import '../../friends/presentation/controllers/friends_controller.dart';
import '../../social/data/feed_api.dart';
import '../../social/domain/feed_share.dart';
import '../../social/presentation/controllers/feed_controller.dart';
import '../data/realtime_socket.dart';
import '../domain/realtime_event.dart';

/// Một người bạn vừa thả cảm xúc vào bài Công khai của mình (SOC-07).
class ReactionNotice {
  const ReactionNotice({required this.seq, required this.reactor, required this.shareEmoji, required this.shareName});

  /// Tăng dần, để hai thông báo giống hệt nhau vẫn được hiện lần lượt.
  final int seq;
  final Reactor reactor;
  final String shareEmoji;
  final String shareName;
}

/// Giữ kết nối WebSocket `/api/me/ws` khi máy đã có tài khoản, và cập nhật app theo sự kiện server
/// đẩy về: feed và danh sách bạn bè tự tải lại, không cần kéo để làm mới. State là thông báo
/// reaction mới nhất (hoặc `null`) để giao diện hiện lên.
final realtimeControllerProvider = NotifierProvider<RealtimeController, ReactionNotice?>(RealtimeController.new);

class RealtimeController extends Notifier<ReactionNotice?> {
  static const pingInterval = Duration(seconds: 25);
  static const maxBackoff = Duration(seconds: 30);

  /// Reaction coi là "vừa thả" khi chưa từng thấy bài đó trước sự kiện.
  static const freshWindow = Duration(seconds: 30);

  RealtimeSocket? _socket;
  StreamSubscription<Object?>? _subscription;
  Timer? _ping;
  Timer? _retry;
  int _attempt = 0;
  String? _token;
  int _seq = 0;

  /// Người đã thả cảm xúc trên từng bài của mình (`userId|emoji`), để biết ai là người mới.
  final _knownReactors = <String, Set<String>>{};

  @override
  ReactionNotice? build() {
    ref.listen<AsyncValue<Account?>>(
      accountControllerProvider,
      (_, next) => _onAccount(next.value),
      fireImmediately: true,
    );
    ref.onDispose(() {
      _token = null;
      _disconnect();
    });
    return null;
  }

  void _onAccount(Account? account) {
    final token = account?.token;
    if (token == _token) return;
    _token = token;
    _attempt = 0;
    _disconnect();
    if (token != null) _connect();
  }

  void _connect() {
    final token = _token;
    if (token == null) return;
    final uri = Uri.parse('${Env.wsBaseUrl}/api/me/ws').replace(queryParameters: {'token': token});
    try {
      final socket = ref.read(realtimeConnectProvider)(uri);
      _socket = socket;
      _subscription = socket.messages.listen(
        _onMessage,
        onError: (_) => _scheduleReconnect(),
        onDone: _scheduleReconnect,
        cancelOnError: true,
      );
      _ping = Timer.periodic(pingInterval, (_) => _socket?.send('ping'));
    } catch (_) {
      _scheduleReconnect();
    }
  }

  void _disconnect() {
    _retry?.cancel();
    _ping?.cancel();
    _subscription?.cancel();
    final socket = _socket;
    _retry = _ping = _subscription = _socket = null;
    if (socket != null) unawaited(socket.close().catchError((_) {}));
  }

  /// Mất kết nối (mạng chập chờn, server khởi động lại): thử lại sau 1, 2, 4… tối đa 30 giây.
  void _scheduleReconnect() {
    _disconnect();
    if (_token == null) return;
    final delay = Duration(seconds: min(maxBackoff.inSeconds, 1 << min(_attempt, 5)));
    _attempt++;
    _retry = Timer(delay, _connect);
  }

  Future<void> _onMessage(Object? message) async {
    final event = RealtimeEvent.tryParse(message);
    if (event == null) return;
    _attempt = 0;
    switch (event) {
      case ShareUpserted() || ShareRemoved():
        ref.invalidate(feedControllerProvider);
      case FriendsChanged():
        ref.invalidate(friendsControllerProvider);
        ref.invalidate(feedControllerProvider);
      case ReactionChanged(:final shareId):
        await _onReactionChanged(shareId);
        ref.invalidate(feedControllerProvider);
    }
  }

  Future<void> _onReactionChanged(String shareId) async {
    final List<Map<String, dynamic>> own;
    try {
      own = await ref.read(feedApiProvider).fetchOwn();
    } catch (_) {
      return; // Không tải được: feed vẫn tự làm mới, chỉ bỏ qua thông báo.
    }
    final json = own.where((s) => s['id'] == shareId).firstOrNull;
    if (json == null) return;
    final share = FeedShare.fromOwnJson(json, ownerId: '', ownerName: '');

    final known = _knownReactors[shareId];
    final now = DateTime.now().toUtc();
    final fresh = share.reactors.where(
      (r) =>
          known == null ? now.difference(r.reactedAt.toUtc()) < freshWindow : !known.contains('${r.userId}|${r.emoji}'),
    );
    _knownReactors[shareId] = {for (final r in share.reactors) '${r.userId}|${r.emoji}'};

    if (fresh.isEmpty) return; // Một người gỡ cảm xúc: không cần báo.
    final latest = fresh.reduce((a, b) => a.reactedAt.isAfter(b.reactedAt) ? a : b);
    state = ReactionNotice(seq: ++_seq, reactor: latest, shareEmoji: share.emoji, shareName: share.name);
  }
}
