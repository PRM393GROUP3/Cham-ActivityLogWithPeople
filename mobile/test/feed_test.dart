import 'package:cham/features/account/data/account_api.dart';
import 'package:cham/features/friends/data/friends_api.dart';
import 'package:cham/features/friends/presentation/controllers/friends_controller.dart';
import 'package:cham/features/social/data/feed_api.dart';
import 'package:cham/features/social/domain/feed_share.dart';
import 'package:cham/features/social/domain/reaction.dart';
import 'package:cham/features/social/presentation/controllers/feed_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/fakes.dart';

FeedShare sample({String? myReaction, Map<String, int> counts = const {}}) => FeedShare(
      id: 's1',
      ownerId: 'u2',
      ownerName: 'Minh Thư',
      emoji: '🏃',
      name: 'Chạy bộ',
      occurredAt: DateTime.utc(2026, 10, 1, 1),
      reactionCounts: counts,
      myReaction: myReaction,
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('Reaction set matches the agreed Facebook-style set (SOC-05)', () {
    expect(Reaction.values.map((r) => r.emoji), ['👍', '❤️', '🥰', '😆', '😮', '😢', '😡']);
  });

  test('FeedShare parses the /api/feed shape', () {
    final share = FeedShare.fromJson({
      'id': 's1',
      'owner': {'id': 'u2', 'displayName': 'Minh Thư'},
      'emoji': '🏃',
      'name': 'Chạy bộ',
      'occurredAt': '2026-10-01T01:00:00.000Z',
      'reactions': [
        {'emoji': '❤️', 'count': 2},
        {'emoji': '😆', 'count': 1},
      ],
      'myReaction': '❤️',
    });
    expect(share.ownerName, 'Minh Thư');
    expect(share.reactionCounts, {'❤️': 2, '😆': 1});
    expect(share.totalReactions, 3);
    expect(share.myReaction, '❤️');
  });

  test('withMyReaction keeps one reaction per person (AC-07)', () {
    final s = sample(myReaction: '❤️', counts: {'❤️': 2});
    expect(s.withMyReaction('😆').reactionCounts, {'❤️': 1, '😆': 1});
    expect(s.withMyReaction(null).reactionCounts, {'❤️': 1});
    expect(sample(counts: {'❤️': 1}).withMyReaction('❤️').reactionCounts, {'❤️': 2});
  });

  group('FeedController', () {
    late FakeFeedApi feedApi;
    late ProviderContainer container;

    setUp(() {
      feedApi = FakeFeedApi([sample()]);
      container = ProviderContainer(overrides: [
        feedApiProvider.overrideWithValue(feedApi),
        accountApiProvider.overrideWithValue(FakeAccountApi()),
        friendsApiProvider.overrideWithValue(FakeFriendsApi()),
      ]);
      addTearDown(container.dispose);
    });

    FeedShare current() => container.read(feedControllerProvider).value!.single;

    test('tap reacts, tapping another emoji switches, tapping again removes', () async {
      await container.read(feedControllerProvider.future);
      final ctrl = container.read(feedControllerProvider.notifier);

      await ctrl.toggleReaction('s1', '❤️');
      expect(current().myReaction, '❤️');
      await ctrl.toggleReaction('s1', '😮');
      expect(current().myReaction, '😮');
      expect(current().reactionCounts, {'😮': 1});
      await ctrl.toggleReaction('s1', '😮');
      expect(current().myReaction, isNull);
      expect(feedApi.reacted, [('s1', '❤️'), ('s1', '😮'), ('s1', null)]);
    });

    test('rolls back the optimistic reaction when the server refuses', () async {
      await container.read(feedControllerProvider.future);
      feedApi.failReact = true;
      await expectLater(container.read(feedControllerProvider.notifier).toggleReaction('s1', '👍'), throwsA(anything));
      expect(current().myReaction, isNull);
    });

    test('adding a friend by invite code refreshes friends and the feed (SOC-01)', () async {
      await container.read(friendsControllerProvider.future);
      final friend = await container.read(friendsControllerProvider.notifier).add(' ABC123 ');
      expect(friend.displayName, 'Bạn ABC123');
      expect((await container.read(friendsControllerProvider.future)).single.id, 'f-ABC123');
    });
  });

  group('own Public posts in the feed (who reacted to me)', () {
    Map<String, dynamic> ownJson({required String id, required String at, List<Map<String, dynamic>> reactions = const []}) => {
          'id': id,
          'emoji': '☕',
          'name': 'Cà phê',
          'occurredAt': at,
          'reactions': reactions,
          'createdAt': at,
          'updatedAt': at,
        };
    Map<String, dynamic> reaction(String name, String emoji, {String? avatar}) => {
          'user': {'id': 'id-$name', 'displayName': name, 'avatarEmoji': avatar},
          'emoji': emoji,
          'reactedAt': '2026-10-01T02:00:00.000Z',
        };

    test('FeedShare.fromOwnJson counts reactions and keeps who reacted', () {
      final share = FeedShare.fromOwnJson(
        ownJson(id: 'm1', at: '2026-10-01T01:00:00Z', reactions: [reaction('Thư', '🥰', avatar: '🦊'), reaction('An', '🥰'), reaction('Bình', '😆')]),
        ownerId: 'me',
        ownerName: 'Bạn',
      );
      expect(share.isMine, isTrue);
      expect(share.reactionCounts, {'🥰': 2, '😆': 1});
      expect(share.reactors.map((r) => (r.displayName, r.emoji, r.avatarEmoji)).first, ('Thư', '🥰', '🦊'));
      expect(share.myReaction, isNull);
    });

    test('the feed mixes my posts with friends\' posts, newest first, and I cannot react to mine', () async {
      final api = FakeFeedApi([sample()], own: [
        ownJson(id: 'mine-new', at: '2026-10-01T03:00:00Z', reactions: [reaction('Thư', '❤️')]),
        ownJson(id: 'mine-old', at: '2026-09-30T03:00:00Z'),
      ]);
      final c = ProviderContainer(overrides: [
        feedApiProvider.overrideWithValue(api),
        accountApiProvider.overrideWithValue(FakeAccountApi()),
      ]);
      addTearDown(c.dispose);

      final feed = await c.read(feedControllerProvider.future);
      expect(feed.map((s) => s.id), ['mine-new', 's1', 'mine-old']); // s1 lúc 01:00 ngày 1/10
      expect(feed.first.isMine, isTrue);
      expect(feed.first.ownerId, 'me');

      await c.read(feedControllerProvider.notifier).toggleReaction('mine-new', '👍');
      expect(api.reacted, isEmpty);
    });
  });
}
