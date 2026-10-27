import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/feed_share.dart';

final feedApiProvider = Provider<FeedApi>((ref) => FeedApi(ref.watch(dioProvider)));

class FeedApi {
  FeedApi(this._dio);

  final Dio _dio;

  /// Bản ghi Public của bạn bè, mới nhất trước.
  Future<List<FeedShare>> fetch({int limit = 50}) => guardApi(() async {
        final res = await _dio.get<Map<String, dynamic>>('/feed', queryParameters: {'limit': limit});
        return (res.data!['data'] as List).map((e) => FeedShare.fromJson(e as Map<String, dynamic>)).toList();
      });

  /// Bài Công khai của chính mình, kèm ai đã thả cảm xúc gì (`GET /api/shares`).
  Future<List<Map<String, dynamic>>> fetchOwn({int limit = 50}) => guardApi(() async {
        final res = await _dio.get<Map<String, dynamic>>('/shares', queryParameters: {'limit': limit});
        return (res.data!['data'] as List).cast<Map<String, dynamic>>();
      });

  Future<FeedShare> react(String shareId, String emoji) => guardApi(() async {
        final res = await _dio.put<Map<String, dynamic>>('/feed/$shareId/reaction', data: {'emoji': emoji});
        return FeedShare.fromJson(res.data!['data'] as Map<String, dynamic>);
      });

  Future<void> unreact(String shareId) => guardApi(() => _dio.delete<void>('/feed/$shareId/reaction'));
}
