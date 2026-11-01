import 'dart:async';
import 'dart:convert';

import 'package:cham/features/account/data/account_api.dart';
import 'package:cham/features/friends/data/friends_api.dart';
import 'package:cham/features/friends/presentation/controllers/friends_controller.dart';
import 'package:cham/features/realtime/data/realtime_socket.dart';
import 'package:cham/features/realtime/domain/realtime_event.dart';
import 'package:cham/features/realtime/presentation/realtime_controller.dart';
import 'package:cham/features/realtime/presentation/widgets/realtime_host.dart';
import 'package:cham/features/social/data/feed_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/fakes.dart';

/// Socket giả: test đẩy tin vào [server], ghi lại các lần kết nối và tin app gửi đi.
class FakeSockets {
  final uris = <Uri>[];
  final sent = <String>[];
  late StreamController<Object?> server;

  RealtimeSocket connect(Uri uri) {
    uris.add(uri);
    server = StreamController<Object?>();
    return RealtimeSocket(messages: server.stream, send: sent.add, close: () async {});
  }

  void push(Map<String, dynamic> event) => server.add(jsonEncode(event));
}

Map<String, dynamic> ownShare(String id, List<({String user, String name, String emoji, DateTime at})> reactors) => {
  'id': id,
  'emoji': '🏃',
  'name': 'Chạy bộ',
  'occurredAt': DateTime.now().toUtc().toIso8601String(),
  'reactions': [
    for (final r in reactors)
      {
        'user': {'id': r.user, 'displayName': r.name, 'avatarEmoji': '🐻'},
        'emoji': r.emoji,
        'reactedAt': r.at.toIso8601String(),
      },
  ],
};

void main() {
  group('RealtimeEvent.tryParse', () {
    test('understands the four server events', () {
      expect((RealtimeEvent.tryParse('{"type":"share.upserted","id":"s1"}') as ShareUpserted).id, 's1');
      expect((RealtimeEvent.tryParse('{"type":"share.removed","id":"s2"}') as ShareRemoved).id, 's2');
      expect((RealtimeEvent.tryParse('{"type":"reaction.changed","shareId":"s3"}') as ReactionChanged).shareId, 's3');
      expect(RealtimeEvent.tryParse('{"type":"friends.changed"}'), isA<FriendsChanged>());
    });

    test('ignores pong, unknown types and garbage', () {
      expect(RealtimeEvent.tryParse('pong'), isNull);
      expect(RealtimeEvent.tryParse('{"type":"something.new"}'), isNull);
      expect(RealtimeEvent.tryParse('{not json'), isNull);
      expect(RealtimeEvent.tryParse(42), isNull);
    });
  });

  group('RealtimeController', () {
    late FakeSockets sockets;
    late FakeFeedApi feed;
    late FakeFriendsApi friends;

    ProviderContainer make({bool withAccount = true}) {
      SharedPreferences.setMockInitialValues({if (withAccount) 'cham_account_v1': jsonEncode(testAccount.toJson())});
      sockets = FakeSockets();
      feed = FakeFeedApi([]);
      friends = FakeFriendsApi();
      final c = ProviderContainer(
        overrides: [
          realtimeConnectProvider.overrideWithValue(sockets.connect),
          feedApiProvider.overrideWithValue(feed),
          friendsApiProvider.overrideWithValue(friends),
          accountApiProvider.overrideWithValue(FakeAccountApi()),
        ],
      );
      addTearDown(c.dispose);
      c.listen(realtimeControllerProvider, (_, _) {});
      return c;
    }

    test('connects to /api/me/ws with the token once there is an account', () async {
      make();
      await settle();
      expect(sockets.uris, hasLength(1));
      expect(sockets.uris.single.path, '/api/me/ws');
      expect(sockets.uris.single.queryParameters['token'], testAccount.token);
    });

    test('stays offline without an account (no anonymous sign-up just to listen)', () async {
      make(withAccount: false);
      await settle();
      expect(sockets.uris, isEmpty);
    });

    test('a new reaction on my post becomes a notice naming who reacted with what', () async {
      final c = make();
      await settle();
      final now = DateTime.now().toUtc();
      feed.own = [
        ownShare('s1', [(user: 'k', name: 'Khoa', emoji: '❤️', at: now)]),
      ];

      sockets.push({'type': 'reaction.changed', 'shareId': 's1'});
      await settle();

      final notice = c.read(realtimeControllerProvider)!;
      expect(notice.reactor.displayName, 'Khoa');
      expect(notice.reactor.emoji, '❤️');
      expect(notice.shareName, 'Chạy bộ');

      // Cùng người, cùng cảm xúc (vd. sự kiện lặp): không báo lại.
      sockets.push({'type': 'reaction.changed', 'shareId': 's1'});
      await settle();
      expect(c.read(realtimeControllerProvider)!.seq, notice.seq);

      // Người thứ hai thả: báo người đó.
      feed.own = [
        ownShare('s1', [
          (user: 'k', name: 'Khoa', emoji: '❤️', at: now),
          (user: 'a', name: 'An', emoji: '😆', at: now),
        ]),
      ];
      sockets.push({'type': 'reaction.changed', 'shareId': 's1'});
      await settle();
      expect(c.read(realtimeControllerProvider)!.reactor.displayName, 'An');
    });

    test('an old reaction seen for the first time is not announced', () async {
      final c = make();
      await settle();
      feed.own = [
        ownShare('s1', [
          (user: 'k', name: 'Khoa', emoji: '❤️', at: DateTime.now().toUtc().subtract(const Duration(hours: 1))),
        ]),
      ];
      sockets.push({'type': 'reaction.changed', 'shareId': 's1'});
      await settle();
      expect(c.read(realtimeControllerProvider), isNull);
    });

    test('friends.changed reloads the friends list', () async {
      final c = make();
      final sub = c.listen(friendsControllerProvider, (_, _) {});
      addTearDown(sub.close);
      await settle();
      expect(c.read(friendsControllerProvider).value, isEmpty);

      await friends.add('KHOA');
      sockets.push({'type': 'friends.changed'});
      await settle();
      expect(c.read(friendsControllerProvider).value!.map((f) => f.displayName), ['Bạn KHOA']);
    });

    test('reconnects after the connection drops', () async {
      make();
      await settle();
      await sockets.server.close();
      await settle();
      await Future<void>.delayed(const Duration(milliseconds: 1100));
      expect(sockets.uris, hasLength(2));
    });
  });

  testWidgets('RealtimeHost slides in "Khoa đã thả ❤️" when a friend reacts', (tester) async {
    SharedPreferences.setMockInitialValues({'cham_account_v1': jsonEncode(testAccount.toJson())});
    final sockets = FakeSockets();
    final feed = FakeFeedApi([]);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          realtimeConnectProvider.overrideWithValue(sockets.connect),
          feedApiProvider.overrideWithValue(feed),
          friendsApiProvider.overrideWithValue(FakeFriendsApi()),
          accountApiProvider.overrideWithValue(FakeAccountApi()),
        ],
        child: MaterialApp(
          builder: (context, child) => RealtimeHost(child: child!),
          home: const Scaffold(body: Text('home')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    feed.own = [
      ownShare('s1', [(user: 'k', name: 'Khoa', emoji: '❤️', at: DateTime.now().toUtc())]),
    ];
    await tester.runAsync(() async {
      sockets.push({'type': 'reaction.changed', 'shareId': 's1'});
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();

    expect(find.text('Khoa đã thả ❤️'), findsOneWidget);
    expect(find.text('vào 🏃 Chạy bộ của bạn'), findsOneWidget);

    await tester.pump(RealtimeHost.visibleFor);
    await tester.pumpAndSettle();
    final banner = tester.getTopLeft(find.text('Khoa đã thả ❤️'));
    expect(banner.dy, lessThan(0)); // đã trượt khỏi màn hình
  });
}
