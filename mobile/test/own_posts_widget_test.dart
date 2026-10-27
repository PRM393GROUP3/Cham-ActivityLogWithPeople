import 'package:cham/features/account/data/account_api.dart';
import 'package:cham/features/friends/data/friends_api.dart';
import 'package:cham/features/social/data/feed_api.dart';
import 'package:cham/features/social/presentation/pages/feed_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/fakes.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> pump(WidgetTester tester, List<Map<String, dynamic>> reactions) async {
    tester.view.physicalSize = const Size(420, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());
    final at = DateTime.now().toUtc().subtract(const Duration(minutes: 5)).toIso8601String();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        accountApiProvider.overrideWithValue(FakeAccountApi()),
        friendsApiProvider.overrideWithValue(FakeFriendsApi()),
        feedApiProvider.overrideWithValue(FakeFeedApi([], own: [
          {'id': 'm', 'emoji': '☕', 'name': 'Cà phê', 'occurredAt': at, 'reactions': reactions, 'createdAt': at, 'updatedAt': at},
        ])),
      ],
      child: const MaterialApp(home: FeedPage()),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('my post shows "Bạn" and opens the list of who reacted', (tester) async {
    await pump(tester, [
      {'user': {'id': 'a', 'displayName': 'Minh Thư', 'avatarEmoji': '🦊'}, 'emoji': '🥰', 'reactedAt': DateTime.now().toUtc().toIso8601String()},
      {'user': {'id': 'b', 'displayName': 'An', 'avatarEmoji': null}, 'emoji': '😆', 'reactedAt': DateTime.now().toUtc().toIso8601String()},
    ]);

    expect(find.textContaining('đã chấm ☕ Cà phê'), findsOneWidget);
    expect(find.text('Bạn'), findsWidgets); // tên trên thẻ + mục lọc "Bạn"
    await tester.tap(find.text('2 người đã thả cảm xúc · Xem'));
    await tester.pumpAndSettle();

    expect(find.text('Cảm xúc cho ☕ Cà phê'), findsOneWidget);
    expect(find.text('Minh Thư'), findsOneWidget);
    expect(find.text('🦊'), findsOneWidget);
    expect(find.descendant(of: find.byType(ListTile), matching: find.text('🥰')), findsOneWidget);
  });

  testWidgets('my post without reactions says so', (tester) async {
    await pump(tester, []);
    expect(find.text('Chưa có ai thả cảm xúc'), findsOneWidget);
  });
}
