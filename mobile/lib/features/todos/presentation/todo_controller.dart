import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/todo_api.dart';
import '../data/todo_realtime.dart';
import '../domain/todo.dart';

final todoControllerProvider =
    AsyncNotifierProvider<TodoController, List<Todo>>(TodoController.new);

class TodoController extends AsyncNotifier<List<Todo>> {
  TodoApi get _api => ref.read(todoApiProvider);

  @override
  Future<List<Todo>> build() async {
    // Apply changes made by other clients in realtime.
    ref.listen(todoEventsProvider, (_, next) {
      final event = next.value;
      if (event != null) _apply(event);
    });
    return _api.fetchAll();
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(_api.fetchAll);
  }

  Future<void> add(String title) async {
    _apply(TodoUpserted(await _api.create(title)));
  }

  Future<void> toggle(Todo todo) async {
    final optimistic = todo.copyWith(completed: !todo.completed);
    _apply(TodoUpserted(optimistic));
    try {
      _apply(TodoUpserted(await _api.update(todo.id, completed: optimistic.completed)));
    } catch (_) {
      _apply(TodoUpserted(todo));
      rethrow;
    }
  }

  Future<void> rename(Todo todo, String title) async {
    _apply(TodoUpserted(await _api.update(todo.id, title: title)));
  }

  Future<void> remove(Todo todo) async {
    _apply(TodoDeleted(todo.id));
    try {
      await _api.delete(todo.id);
    } catch (_) {
      _apply(TodoUpserted(todo));
      rethrow;
    }
  }

  /// Idempotent: the same change may arrive both from our own request and the WebSocket.
  void _apply(TodoEvent event) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(switch (event) {
      TodoUpserted(:final todo) => current.any((t) => t.id == todo.id)
          ? [for (final t in current) t.id == todo.id ? todo : t]
          : [todo, ...current],
      TodoDeleted(:final id) => current.where((t) => t.id != id).toList(),
    });
  }
}
