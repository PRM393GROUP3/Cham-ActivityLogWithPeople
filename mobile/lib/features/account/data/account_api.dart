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
          avatarEmoji: user['avatarEmoji'] as String?,
          token: data['token'] as String,
        );
      });

  /// PATCH /api/me — đổi tên và / hoặc avatar. [clearAvatar] = bỏ avatar (về chữ cái đầu).
  Future<Profile> updateProfile({String? displayName, String? avatarEmoji, bool clearAvatar = false}) =>
      guardApi(() async {
        final res = await _dio.patch<Map<String, dynamic>>('/me', data: {
          'displayName': ?displayName,
          if (clearAvatar) 'avatarEmoji': null else 'avatarEmoji': ?avatarEmoji,
        });
        final me = res.data!['data'] as Map<String, dynamic>;
        return (displayName: me['displayName'] as String, avatarEmoji: me['avatarEmoji'] as String?);
      });

  /// POST /api/me/invite-code → mã mời mới; mã cũ (và QR cũ) hết hiệu lực.
  Future<String> rotateInviteCode() => guardApi(() async {
        final res = await _dio.post<Map<String, dynamic>>('/me/invite-code');
        return (res.data!['data'] as Map<String, dynamic>)['inviteCode'] as String;
      });
}
