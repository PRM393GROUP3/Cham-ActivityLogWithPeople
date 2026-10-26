import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/account.dart';

final accountApiProvider = Provider<AccountApi>((ref) => AccountApi(ref.watch(dioProvider)));

class AccountApi {
  AccountApi(this._dio);

  final Dio _dio;

  /// POST /api/auth/register → tài khoản ẩn danh mới kèm token.
  Future<Account> register(String displayName) => guardApi(() async {
        final res = await _dio.post<Map<String, dynamic>>('/auth/register', data: {'displayName': displayName});
        final data = res.data!['data'] as Map<String, dynamic>;
        final user = data['user'] as Map<String, dynamic>;
        return Account(
          id: user['id'] as String,
          displayName: user['displayName'] as String,
          inviteCode: user['inviteCode'] as String,
          token: data['token'] as String,
        );
      });
}
