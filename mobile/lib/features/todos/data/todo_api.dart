import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../domain/todo.dart';

final todoApiProvider = Provider<TodoApi>((ref) => TodoApi(ref.watch(dioProvider)));

class TodoApi {
  TodoApi(this._dio);

  final Dio _dio;

  Future<List<Todo>> fetchAll() => _call(() async {
        final res = await _dio.get<Map<String, dynamic>>('/todos');
        return (res.data!['data'] as List)
            .map((e) => Todo.fromJson(e as Map<String, dynamic>))
            .toList();
      });

  Future<Todo> create(String title) => _call(() async {
        final res = await _dio.post<Map<String, dynamic>>('/todos', data: {'title': title});
        return Todo.fromJson(res.data!['data'] as Map<String, dynamic>);
      });

  Future<Todo> update(String id, {String? title, bool? completed}) => _call(() async {
        final res = await _dio.patch<Map<String, dynamic>>(
          '/todos/$id',
          data: {'title': ?title, 'completed': ?completed},
        );
        return Todo.fromJson(res.data!['data'] as Map<String, dynamic>);
      });

  Future<void> delete(String id) => _call(() => _dio.delete<void>('/todos/$id'));

  Future<T> _call<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on DioException catch (e) {
      throw e.error is ApiException ? e.error! : ApiException.fromDio(e);
    }
  }
}
