import 'dart:typed_data';

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
          username: user['username'] as String?,
          avatarEmoji: user['avatarEmoji'] as String?,
          avatarUrl: user['avatarUrl'] as String?,
          token: data['token'] as String,
        );
      });

  /// PATCH /api/me — đổi tên, tên người dùng và / hoặc avatar. [clearAvatar] = bỏ avatar (về chữ cái đầu).
  /// Tên người dùng đã có người khác dùng → [ApiException] mã `USERNAME_TAKEN`.
  Future<Profile> updateProfile({
    String? displayName,
    String? username,
    String? avatarEmoji,
    bool clearAvatar = false,
  }) =>
      guardApi(() async {
        final res = await _dio.patch<Map<String, dynamic>>('/me', data: {
          'displayName': ?displayName,
          'username': ?username,
          if (clearAvatar) 'avatarEmoji': null else 'avatarEmoji': ?avatarEmoji,
        });
        return _profile(res.data!);
      });

  /// PUT /api/me/avatar — ảnh JPEG / PNG / WebP (≤ 2 MB) làm avatar, thay emoji hoặc ảnh cũ.
  Future<Profile> uploadAvatar(Uint8List bytes) => guardApi(() async {
        final res = await _dio.put<Map<String, dynamic>>(
          '/me/avatar',
          data: bytes,
          options: Options(contentType: 'application/octet-stream'),
        );
        return _profile(res.data!);
      });

  static Profile _profile(Map<String, dynamic> body) {
    final me = body['data'] as Map<String, dynamic>;
    return (
      displayName: me['displayName'] as String,
      username: me['username'] as String?,
      avatarEmoji: me['avatarEmoji'] as String?,
      avatarUrl: me['avatarUrl'] as String?,
    );
  }
}
