import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/todo.dart';
import '../todo_controller.dart';
import '../widgets/todo_tile.dart';

class TodoPage extends ConsumerStatefulWidget {
  const TodoPage({super.key});

  @override
  ConsumerState<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends ConsumerState<TodoPage> {
  final _input = TextEditingController();

  TodoController get _controller => ref.read(todoControllerProvider.notifier);

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _submit() async {
    final title = _input.text.trim();
    if (title.isEmpty) return;
    _input.clear();
    await _run(() => _controller.add(title));
  }

  Future<void> _edit(Todo todo) async {
    final text = TextEditingController(text: todo.title);
    final title = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit todo'),
        content: TextField(
          controller: text,
          autofocus: true,
          onSubmitted: (v) => Navigator.pop(context, v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, text.text), child: const Text('Save')),
        ],
      ),
    );
    text.dispose();
    if (title == null || title.trim().isEmpty || title.trim() == todo.title) return;
    await _run(() => _controller.rename(todo, title.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final todos = ref.watch(todoControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Todos')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: TextField(
                  controller: _input,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    hintText: 'What needs to be done?',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(icon: const Icon(Icons.add), onPressed: _submit),
                  ),
                ),
              ),
              Expanded(
                child: todos.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('$e', textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        FilledButton(onPressed: _controller.refresh, child: const Text('Retry')),
                      ],
                    ),
                  ),
                  data: (items) => RefreshIndicator(
                    onRefresh: _controller.refresh,
                    child: items.isEmpty
                        ? ListView(children: const [
                            SizedBox(height: 120),
                            Center(child: Text('No todos yet')),
                          ])
                        : ListView.builder(
                            itemCount: items.length,
                            itemBuilder: (context, i) {
                              final todo = items[i];
                              return TodoTile(
                                todo: todo,
                                onToggle: () => _run(() => _controller.toggle(todo)),
                                onEdit: () => _edit(todo),
                                onDelete: () => _run(() => _controller.remove(todo)),
                              );
                            },
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
