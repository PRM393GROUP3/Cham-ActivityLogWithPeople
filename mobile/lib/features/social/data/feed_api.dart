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

  Future<FeedShare> react(String shareId, String emoji) => guardApi(() async {
        final res = await _dio.put<Map<String, dynamic>>('/feed/$shareId/reaction', data: {'emoji': emoji});
        return FeedShare.fromJson(res.data!['data'] as Map<String, dynamic>);
      });

  Future<void> unreact(String shareId) => guardApi(() => _dio.delete<void>('/feed/$shareId/reaction'));
}
