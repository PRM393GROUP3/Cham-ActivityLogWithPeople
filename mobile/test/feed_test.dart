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
}
