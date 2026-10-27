import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/friend.dart';

final friendsApiProvider = Provider<FriendsApi>((ref) => FriendsApi(ref.watch(dioProvider)));

class FriendsApi {
  FriendsApi(this._dio);

  final Dio _dio;

  Future<List<Friend>> list() => guardApi(() async {
        final res = await _dio.get<Map<String, dynamic>>('/friends');
        return (res.data!['data'] as List).map((e) => Friend.fromJson(e as Map<String, dynamic>)).toList();
      });

  /// Kết bạn trực tiếp bằng mã mời đọc từ QR (SOC-01): không cần người kia xác nhận.
  Future<Friend> add(String inviteCode) => guardApi(() async {
        final res = await _dio.post<Map<String, dynamic>>('/friends', data: {'inviteCode': inviteCode});
        return Friend.fromJson(res.data!['data'] as Map<String, dynamic>);
      });

  Future<void> remove(String friendId) => guardApi(() => _dio.delete<void>('/friends/$friendId'));
}
