import 'dart:convert';
import 'dart:typed_data';

import 'package:cham/core/utils/image_saver/image_saver.dart';
import 'package:cham/features/account/data/account_api.dart';
import 'package:cham/features/activity_dial/domain/activity_log.dart';
import 'package:cham/features/activity_dial/presentation/pages/activity_dial_page.dart';
import 'package:cham/features/friends/data/friends_api.dart';
import 'package:cham/features/friends/domain/friend.dart';
import 'package:cham/features/sharing/data/share_api.dart';
import 'package:cham/features/social/data/feed_api.dart';
import 'package:cham/features/social/domain/feed_share.dart';
import 'package:cham/features/social/domain/story_user.dart';
import 'package:cham/features/social/presentation/pages/feed_page.dart';
import 'package:cham/features/social/presentation/widgets/friend_day_dial.dart';
import 'package:cham/features/stats/domain/activity_stats.dart';
import 'package:cham/features/stats/presentation/pages/stats_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/fakes.dart';

FeedShare share(String id, String owner, String emoji, String name, DateTime at) => FeedShare(
  id: id,
  ownerId: owner,
  ownerName: 'Khoa',
  ownerAvatarEmoji: '🐻',
  emoji: emoji,
  name: name,
  occurredAt: at,
);

void phone(WidgetTester tester, {double height = 1400}) {
  tester.view.physicalSize = Size(420, height);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() => tester.view.resetPhysicalSize());
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('Ngày của bạn bè (SOC-08)', () {
    test('sharesOfToday keeps only that person\'s posts from today (VN), earliest first', () {
      final now = DateTime.utc(2026, 11, 1, 5); // 12:00 giờ VN
      final shares = [
        share('late', 'k', '🏃', 'Chạy bộ', DateTime.utc(2026, 11, 1, 4)),
        share('early', 'k', '☕', 'Cà phê', DateTime.utc(2026, 10, 31, 18)), // 01:00 giờ VN hôm nay
        share('yesterday', 'k', '🌙', 'Ngủ', DateTime.utc(2026, 10, 31, 16)), // 23:00 giờ VN hôm qua
        share('other', 'a', '📖', 'Đọc sách', DateTime.utc(2026, 11, 1, 3)),
      ];
      expect(sharesOfToday(shares, 'k', now: now).map((s) => s.id), ['early', 'late']);
    });

    testWidgets('picking a friend on the stories bar opens their day on a mini dial', (tester) async {
      phone(tester);
      final now = DateTime.now().toUtc();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            accountApiProvider.overrideWithValue(FakeAccountApi()),
            friendsApiProvider.overrideWithValue(
              FakeFriendsApi([
                Friend(id: 'k', displayName: 'Khoa', avatarEmoji: '🐻', since: DateTime.utc(2026, 10, 1)),
              ]),
            ),
            feedApiProvider.overrideWithValue(
              FakeFeedApi([
                share('s1', 'k', '🍜', 'Ăn uống', now.subtract(const Duration(minutes: 30))),
                share('s2', 'k', '🏃', 'Chạy bộ', now.subtract(const Duration(minutes: 5))),
              ]),
            ),
          ],
          child: const MaterialApp(home: FeedPage()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(FriendDayDial), findsNothing);

      await tester.tap(find.text('Khoa').first);
      await tester.pumpAndSettle();

      expect(find.text('Ngày của Khoa'), findsOneWidget);
      expect(find.text('2 chấm Công khai hôm nay'), findsOneWidget);
      expect(find.descendant(of: find.byType(FriendDayDial), matching: find.text('🍜')), findsOneWidget);
      expect(find.descendant(of: find.byType(FriendDayDial), matching: find.text('🏃')), findsOneWidget);

      await tester.tap(find.text('Tất cả'));
      await tester.pumpAndSettle();
      expect(find.byType(FriendDayDial), findsNothing);
    });

    testWidgets('a friend with nothing public today says so', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: FriendDayDial(
                user: const StoryUser(id: 'k', name: 'Khoa'),
                shares: const [],
              ),
            ),
          ),
        ),
      );
      expect(find.text('Hôm nay Khoa chưa chấm Công khai gì'), findsOneWidget);
    });
  });

  group('Reaction burst', () {
    testWidgets('tapping a reaction flies the emoji up from the button, then it disappears', (tester) async {
      phone(tester);
      final now = DateTime.now().toUtc();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            accountApiProvider.overrideWithValue(FakeAccountApi()),
            friendsApiProvider.overrideWithValue(FakeFriendsApi()),
            feedApiProvider.overrideWithValue(FakeFeedApi([share('s1', 'k', '🏃', 'Chạy bộ', now)])),
          ],
          child: const MaterialApp(home: FeedPage()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('❤️'), findsOneWidget);

      await tester.tap(find.text('❤️'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('❤️'), findsNWidgets(2)); // nút + emoji đang bay
      await tester.pumpAndSettle();
      expect(find.text('❤️'), findsOneWidget);
      expect(find.text('1'), findsOneWidget); // số đếm trên nút
    });
  });

  group('Hiệu ứng khi chấm', () {
    testWidgets('tapping a dial node shows a ripple with "+1" and a toast with the time', (tester) async {
      phone(tester, height: 1000);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            accountApiProvider.overrideWithValue(FakeAccountApi()),
            shareApiProvider.overrideWithValue(FakeShareApi()),
          ],
          child: const MaterialApp(home: ActivityDialPage()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Chạy bộ'));
      await tester.pump(); // khung đầu tiên khởi động animation
      await tester.pump(const Duration(milliseconds: 150));
      expect(find.text('+1'), findsOneWidget);
      expect(find.textContaining(RegExp(r'^Đã chấm Chạy bộ lúc \d\d:\d\d$')), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.text('+1'), findsNothing);
    });
  });

  group('Ảnh tóm tắt (STA-02)', () {
    testWidgets('builds a "Tuần của tôi" card from the week and saves it as a PNG', (tester) async {
      phone(tester, height: 2400);
      final now = DateTime.now().toUtc();
      SharedPreferences.setMockInitialValues({
        'cham_activity_logs_v1': jsonEncode([
          for (var i = 0; i < 3; i++)
            ActivityLog(
              id: 'c$i',
              eventTypeId: 'coffee',
              name: 'Cà phê',
              emoji: '☕',
              occurredAt: now.subtract(Duration(minutes: i + 1)),
            ).toJson(),
          ActivityLog(
            id: 'r',
            eventTypeId: 'run',
            name: 'Chạy bộ',
            emoji: '🏃',
            occurredAt: now.subtract(const Duration(minutes: 9)),
          ).toJson(),
        ]),
      });
      final saved = <(Uint8List, String)>[];
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            accountApiProvider.overrideWithValue(FakeAccountApi()),
            shareApiProvider.overrideWithValue(FakeShareApi()),
            pngSaverProvider.overrideWithValue((bytes, {required fileName}) async {
              saved.add((bytes, fileName));
              return 'saved-ok';
            }),
          ],
          child: const MaterialApp(home: StatsPage(initialPeriod: StatsPeriod.week)),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('open-recap')));
      await tester.pumpAndSettle();
      expect(find.text('Tuần của tôi'), findsOneWidget);
      expect(find.text('4'), findsWidgets);
      expect(find.text('3 lần'), findsOneWidget); // Cà phê đứng đầu

      await tester.runAsync(() async {
        await tester.tap(find.text('Lưu ảnh'));
        await Future<void>.delayed(const Duration(milliseconds: 500));
      });
      await tester.pumpAndSettle();
      expect(saved.single.$2, startsWith('cham-tuan-'));
      expect(saved.single.$1.sublist(1, 4), 'PNG'.codeUnits);
      expect(find.text('saved-ok'), findsOneWidget);
    });

    testWidgets('the recap button is disabled when the range is empty', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            accountApiProvider.overrideWithValue(FakeAccountApi()),
            shareApiProvider.overrideWithValue(FakeShareApi()),
          ],
          child: const MaterialApp(home: StatsPage()),
        ),
      );
      await tester.pumpAndSettle();
      // Không có bản ghi nào trong storage: app tự tạo 4 bản mẫu hôm nay, nên xem Tháng trước.
      await tester.tap(find.byTooltip('Trước'));
      await tester.pumpAndSettle();
      expect(tester.widget<IconButton>(find.byKey(const ValueKey('open-recap'))).onPressed, isNull);
    });
  });
}
