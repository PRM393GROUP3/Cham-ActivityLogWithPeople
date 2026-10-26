import 'package:cham/features/account/data/account_api.dart';
import 'package:cham/features/account/data/account_storage.dart';
import 'package:cham/features/account/domain/account.dart';
import 'package:cham/features/account/domain/avatar.dart';
import 'package:cham/features/account/presentation/account_controller.dart';
import 'package:cham/features/account/presentation/pages/edit_profile_page.dart';
import 'package:cham/features/account/presentation/widgets/user_avatar.dart';
import 'package:cham/features/friends/data/friends_api.dart';
import 'package:cham/features/friends/domain/friend.dart';
import 'package:cham/features/friends/presentation/pages/friends_page.dart';
import 'package:cham/features/social/domain/feed_share.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/fakes.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('isSingleEmoji', () {
    test('accepts one emoji, including multi-codepoint ones', () {
      for (final e in ['😀', '🐼', '☕', '⭐', '👩‍💻', '👍🏽', '🇻🇳', ' 🦊 ']) {
        expect(isSingleEmoji(e), isTrue, reason: e);
      }
    });

    test('rejects letters, digits, several emoji and empty input', () {
      for (final e in ['a', 'An', '1', '#', '', '😀😀', '😀 hi']) {
        expect(isSingleEmoji(e), isFalse, reason: e);
      }
    });
  });

  test('Account keeps the avatar through JSON (and works without one)', () {
    const a = Account(id: 'i', displayName: 'An', inviteCode: 'C', token: 't', avatarEmoji: '🐼');
    expect(Account.fromJson(a.toJson()).avatarEmoji, '🐼');
    expect(Account.fromJson(a.copyWith(avatarEmoji: () => null).toJson()).avatarEmoji, isNull);
  });

  test('FeedShare and Friend read avatarEmoji from the API', () {
    final share = FeedShare.fromJson({
      'id': 's',
      'owner': {'id': 'u', 'displayName': 'Thư', 'avatarEmoji': '🦊'},
      'emoji': '🏃',
      'name': 'Chạy bộ',
      'occurredAt': '2026-10-01T00:00:00Z',
      'reactions': [],
      'myReaction': null,
    });
    expect(share.ownerAvatarEmoji, '🦊');
    expect(Friend.fromJson({'id': 'u', 'displayName': 'Thư', 'since': '2026-10-01T00:00:00Z'}).avatarEmoji, isNull);
  });

  group('AccountController.updateProfile', () {
    test('registers on first use, saves name + avatar locally, and can clear the avatar', () async {
      final api = FakeAccountApi();
      final c = ProviderContainer(overrides: [accountApiProvider.overrideWithValue(api)]);
      addTearDown(c.dispose);

      await c.read(accountControllerProvider.notifier).updateProfile(displayName: 'Thư', avatarEmoji: '🐼');
      expect(api.calls, 1);
      expect(api.profileUpdates.single, (displayName: 'Thư', avatarEmoji: '🐼', clearAvatar: false));
      final stored = await AccountStorage().load();
      expect((stored!.displayName, stored.avatarEmoji), ('Thư', '🐼'));

      await c.read(accountControllerProvider.notifier).updateProfile(displayName: 'Thư', avatarEmoji: null);
      expect(api.profileUpdates.last.clearAvatar, isTrue);
      expect(c.read(accountControllerProvider).value!.avatarEmoji, isNull);
    });
  });

  group('EditProfilePage', () {
    Future<FakeAccountApi> pump(WidgetTester tester, {bool online = true}) async {
      tester.view.physicalSize = const Size(420, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());
      final api = FakeAccountApi()..online = online;
      await tester.pumpWidget(ProviderScope(
        overrides: [accountApiProvider.overrideWithValue(api)],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const EditProfilePage())),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      return api;
    }

    testWidgets('pick an avatar, set a name, save', (tester) async {
      final api = await pump(tester);
      expect(tester.widget<TextField>(find.byKey(const ValueKey('profile-name'))).controller!.text, 'Bạn');

      await tester.enterText(find.byKey(const ValueKey('profile-name')), 'Minh Thư');
      await tester.tap(find.byKey(const ValueKey('avatar-🦊')));
      await tester.pump();
      expect(find.descendant(of: find.byType(UserAvatar), matching: find.text('🦊')), findsOneWidget);

      await tester.tap(find.text('Lưu'));
      await tester.pumpAndSettle();
      expect(api.profileUpdates.single, (displayName: 'Minh Thư', avatarEmoji: '🦊', clearAvatar: false));
      expect(find.text('Đã lưu hồ sơ'), findsOneWidget);
    });

    testWidgets('a custom emoji works; text that is not one emoji is refused', (tester) async {
      final api = await pump(tester);
      await tester.enterText(find.byKey(const ValueKey('profile-custom-emoji')), 'hi');
      await tester.tap(find.text('Lưu'));
      await tester.pump();
      expect(find.text('Avatar phải là đúng một emoji.'), findsOneWidget);
      expect(api.profileUpdates, isEmpty);

      await tester.enterText(find.byKey(const ValueKey('profile-custom-emoji')), '👩‍💻');
      await tester.tap(find.text('Lưu'));
      await tester.pumpAndSettle();
      expect(api.profileUpdates.single.avatarEmoji, '👩‍💻');
    });

    testWidgets('empty name is refused; offline shows the error and keeps the page open', (tester) async {
      final api = await pump(tester, online: false);
      await tester.enterText(find.byKey(const ValueKey('profile-name')), '   ');
      await tester.tap(find.text('Lưu'));
      await tester.pump();
      expect(find.text('Hãy nhập tên hiển thị.'), findsOneWidget);

      await tester.enterText(find.byKey(const ValueKey('profile-name')), 'An');
      await tester.tap(find.text('Lưu'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Không lưu được'), findsOneWidget);
      expect(find.text('Hồ sơ của bạn'), findsOneWidget);
      expect(api.profileUpdates, isEmpty);
    });
  });

  testWidgets('friends list shows the friend avatar emoji, or initials without one', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        accountApiProvider.overrideWithValue(FakeAccountApi()),
        friendsApiProvider.overrideWithValue(FakeFriendsApi([
          Friend(id: 'a', displayName: 'Thư', since: DateTime.utc(2026, 10, 1), avatarEmoji: '🦊'),
          Friend(id: 'b', displayName: 'long', since: DateTime.utc(2026, 10, 1)),
        ])),
      ],
      child: const MaterialApp(home: FriendsPage()),
    ));
    await tester.pumpAndSettle();
    expect(find.text('🦊'), findsOneWidget);
    expect(find.text('L'), findsOneWidget);
  });
}
