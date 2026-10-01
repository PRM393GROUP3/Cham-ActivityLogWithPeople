class Todo {
  const Todo({
    required this.id,
    required this.title,
    required this.completed,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final bool completed;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory Todo.fromJson(Map<String, dynamic> json) => Todo(
        id: json['id'] as String,
        title: json['title'] as String,
        completed: json['completed'] as bool,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );

  Todo copyWith({String? title, bool? completed}) => Todo(
        id: id,
        title: title ?? this.title,
        completed: completed ?? this.completed,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}

/// Realtime events pushed by the backend over WebSocket.
sealed class TodoEvent {
  const TodoEvent();

  static TodoEvent? fromJson(Map<String, dynamic> json) => switch (json['type']) {
        'todo.created' => TodoUpserted(Todo.fromJson(json['todo'] as Map<String, dynamic>)),
        'todo.updated' => TodoUpserted(Todo.fromJson(json['todo'] as Map<String, dynamic>)),
        'todo.deleted' => TodoDeleted(json['id'] as String),
        _ => null,
      };
}

class TodoUpserted extends TodoEvent {
  const TodoUpserted(this.todo);
  final Todo todo;
}

class TodoDeleted extends TodoEvent {
  const TodoDeleted(this.id);
  final String id;
}
