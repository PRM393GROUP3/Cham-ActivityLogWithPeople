import 'package:cham/features/todos/domain/todo.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses realtime events from the backend', () {
    final todo = {
      'id': '1',
      'title': 'Buy milk',
      'completed': false,
      'createdAt': '2026-10-01T00:00:00.000Z',
      'updatedAt': '2026-10-01T00:00:00.000Z',
    };
    expect(TodoEvent.fromJson({'type': 'todo.created', 'todo': todo}), isA<TodoUpserted>());
    expect(TodoEvent.fromJson({'type': 'todo.deleted', 'id': '1'}), isA<TodoDeleted>());
    expect(TodoEvent.fromJson({'type': 'unknown'}), isNull);
  });
}
