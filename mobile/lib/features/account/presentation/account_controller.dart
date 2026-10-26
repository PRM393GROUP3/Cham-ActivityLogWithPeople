import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/account_api.dart';
import '../data/account_storage.dart';
import '../domain/account.dart';

/// Tài khoản đã lưu trên máy, hoặc `null` khi người dùng chưa dùng tính năng xã hội lần nào.
final accountControllerProvider = AsyncNotifierProvider<AccountController, Account?>(AccountController.new);

class AccountController extends AsyncNotifier<Account?> {
  static const defaultDisplayName = 'Bạn';

  Future<Account>? _registering;

  @override
  Future<Account?> build() => ref.read(accountStorageProvider).load();

  /// Trả về tài khoản, tự đăng ký ẩn danh ở lần đầu cần dùng tính năng xã hội.
  /// Cần mạng ở lần đầu; ném [ApiException] nếu không kết nối được.
  Future<Account> ensure() async {
    Account? existing;
    try {
      existing = await future;
    } catch (_) {
      // Lần đăng ký trước thất bại (state đang là lỗi): thử lại bên dưới.
    }
    if (existing != null) return existing;
    return _registering ??= _register().whenComplete(() => _registering = null);
  }

  /// Đổi mã mời: người đã có mã cũ / ảnh QR cũ không kết bạn được nữa (bạn bè hiện có giữ nguyên).
  Future<Account> rotateInviteCode() async {
    final account = await ensure();
    final updated = account.copyWith(inviteCode: await ref.read(accountApiProvider).rotateInviteCode());
    await ref.read(accountStorageProvider).save(updated);
    state = AsyncData(updated);
    return updated;
  }

  Future<Account> _register() async {
    state = const AsyncLoading();
    try {
      final account = await ref.read(accountApiProvider).register(defaultDisplayName);
      await ref.read(accountStorageProvider).save(account);
      state = AsyncData(account);
      return account;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}
