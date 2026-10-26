import 'package:cham/core/network/api_exception.dart';
import 'package:cham/features/account/data/account_api.dart';
import 'package:cham/features/account/domain/account.dart';
import 'package:cham/features/friends/data/friends_api.dart';
import 'package:cham/features/friends/domain/friend.dart';
import 'package:cham/features/sharing/data/share_api.dart';
import 'package:cham/features/sharing/domain/share_op.dart';
import 'package:cham/features/social/data/feed_api.dart';
import 'package:cham/features/social/domain/feed_share.dart';

const offline = ApiException('NETWORK_ERROR', 'offline');

const testAccount = Account(id: 'me', displayName: 'Bạn', inviteCode: 'MYCODE', token: 't0k3n');

class FakeAccountApi implements AccountApi {
  int calls = 0;
  bool online = true;

  @override
  Future<Account> register(String displayName) async {
    calls++;
    if (!online) throw offline;
    return testAccount;
  }
}

class FakeShareApi implements ShareApi {
  final sent = <ShareOp>[];
  bool online = true;

  @override
  Future<void> send(ShareOp op) async {
    if (!online) throw offline;
    sent.add(op);
  }
}

class FakeFeedApi implements FeedApi {
  FakeFeedApi(this.shares);

  List<FeedShare> shares;
  bool failReact = false;
  final reacted = <(String, String?)>[];

  @override
  Future<List<FeedShare>> fetch({int limit = 50}) async => shares;

  @override
  Future<FeedShare> react(String shareId, String emoji) async {
    if (failReact) throw const ApiException('VALIDATION_ERROR', 'bad', statusCode: 400);
    reacted.add((shareId, emoji));
    return shares.firstWhere((s) => s.id == shareId).withMyReaction(emoji);
  }

  @override
  Future<void> unreact(String shareId) async {
    if (failReact) throw const ApiException('VALIDATION_ERROR', 'bad', statusCode: 400);
    reacted.add((shareId, null));
  }
}

class FakeFriendsApi implements FriendsApi {
  FakeFriendsApi([List<Friend>? friends]) : friends = friends ?? [];

  final List<Friend> friends;

  @override
  Future<List<Friend>> list() async => List.of(friends);

  @override
  Future<Friend> add(String inviteCode) async {
    if (inviteCode == 'BAD') throw const ApiException('NOT_FOUND', 'Mã mời không tồn tại', statusCode: 404);
    final friend = Friend(id: 'f-$inviteCode', displayName: 'Bạn $inviteCode', since: DateTime.utc(2026, 10, 1));
    friends.add(friend);
    return friend;
  }

  @override
  Future<void> remove(String friendId) async => friends.removeWhere((f) => f.id == friendId);
}

/// Cho các microtask / Future khởi tạo của Notifier chạy xong.
Future<void> settle() async {
  for (var i = 0; i < 30; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}
