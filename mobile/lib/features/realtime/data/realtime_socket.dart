import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Một kết nối WebSocket đang mở: luồng tin nhận về, gửi chuỗi, và đóng.
class RealtimeSocket {
  const RealtimeSocket({required this.messages, required this.send, required this.close});

  final Stream<Object?> messages;
  final void Function(String message) send;
  final Future<void> Function() close;
}

typedef RealtimeConnect = RealtimeSocket Function(Uri uri);

/// Mở WebSocket thật. Test ghi đè provider này bằng socket giả.
final realtimeConnectProvider = Provider<RealtimeConnect>(
  (ref) => (uri) {
    final channel = WebSocketChannel.connect(uri);
    return RealtimeSocket(messages: channel.stream, send: channel.sink.add, close: () async => channel.sink.close());
  },
);
