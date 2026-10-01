import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../core/config/env.dart';
import '../domain/todo.dart';

/// Stream of todo changes from the backend's Durable Object, reconnecting on drop.
final todoEventsProvider = StreamProvider<TodoEvent>((ref) {
  final controller = StreamController<TodoEvent>();
  WebSocketChannel? channel;
  Timer? retry;
  var disposed = false;

  void connect() {
    if (disposed) return;
    channel = WebSocketChannel.connect(Uri.parse('${Env.wsBaseUrl}/api/todos/ws'));
    channel!.stream.listen(
      (raw) {
        if (raw is! String || raw == 'pong') return;
        final event = TodoEvent.fromJson(jsonDecode(raw) as Map<String, dynamic>);
        if (event != null) controller.add(event);
      },
      onError: (_) {},
      onDone: () => retry = Timer(const Duration(seconds: 3), connect),
      cancelOnError: true,
    );
  }

  connect();
  ref.onDispose(() {
    disposed = true;
    retry?.cancel();
    channel?.sink.close();
    controller.close();
  });
  return controller.stream;
});
