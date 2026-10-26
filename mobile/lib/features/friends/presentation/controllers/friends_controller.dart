import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../account/presentation/account_controller.dart';
import '../../../social/presentation/controllers/feed_controller.dart';
import '../../data/friends_api.dart';
import '../../domain/friend.dart';

/// Danh sách bạn bè (SOC-02). Tự tạo tài khoản ẩn danh ở lần đầu (cần mạng).
final friendsControllerProvider = AsyncNotifierProvider<FriendsController, List<Friend>>(FriendsController.new);

class FriendsController extends AsyncNotifier<List<Friend>> {
  FriendsApi get _api => ref.read(friendsApiProvider);

  @override
  Future<List<Friend>> build() async {
    await ref.read(accountControllerProvider.notifier).ensure();
    return _api.list();
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(build);
  }

  /// Kết bạn bằng mã mời; feed được tải lại vì bạn mới thấy được cả các bản Public cũ.
  Future<Friend> add(String inviteCode) async {
    await ref.read(accountControllerProvider.notifier).ensure();
    final friend = await _api.add(inviteCode.trim());
    await refresh();
    ref.invalidate(feedControllerProvider);
    return friend;
  }

  Future<void> remove(String friendId) async {
    await _api.remove(friendId);
    await refresh();
    ref.invalidate(feedControllerProvider);
  }
}
