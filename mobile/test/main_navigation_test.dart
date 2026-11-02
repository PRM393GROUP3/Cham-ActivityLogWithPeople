import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cham/features/shell/presentation/pages/main_shell_page.dart';
import 'package:cham/features/widgets/presentation/pages/widget_selection_page.dart';
import 'package:cham/features/friends/presentation/pages/add_qr_page.dart';
import 'package:cham/features/account/data/account_api.dart';
import 'package:cham/features/friends/data/friends_api.dart';
import 'package:cham/features/friends/domain/friend.dart';
import 'package:cham/features/social/data/feed_api.dart';
import 'package:cham/features/social/domain/feed_share.dart';

import 'helpers/fakes.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('MainShellPage: swipe up to Bạn bè, sideways to Phân tích / Lịch sử, Back retraces',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(420, 920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountApiProvider.overrideWithValue(FakeAccountApi()),
          friendsApiProvider.overrideWithValue(
            FakeFriendsApi([Friend(id: 'u2', displayName: 'Minh Thư', since: DateTime.utc(2026, 10, 1))]),
          ),
          feedApiProvider.overrideWithValue(FakeFeedApi([
            FeedShare(
              id: 's1',
              ownerId: 'u2',
              ownerName: 'Minh Thư',
              emoji: '🏃',
              name: 'Chạy bộ',
              occurredAt: DateTime.now().subtract(const Duration(minutes: 15)),
            ),
          ])),
        ],
        child: MaterialApp(
          routes: {
            '/widgets': (context) => const WidgetSelectionPage(),
            '/add-qr': (context) => const AddQrPage(animateLaser: false, enableCamera: false),
          },
          home: const MainShellPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Initial State: ActivityDialPage is visible
    expect(find.text('Chấm'), findsOneWidget);
    expect(find.textContaining('HÔM NAY'), findsOneWidget);

    final center = tester.getCenter(find.byType(MainShellPage));

    // 2. Swipe up from Home to the friends feed below it
    await tester.dragFrom(center, const Offset(0, -500));
    await tester.pumpAndSettle();

    // Verify FeedPage shows friends and their Public records from the API
    expect(find.text('Bạn bè'), findsOneWidget);
    expect(find.text('Tất cả'), findsOneWidget);
    expect(find.text('Minh Thư'), findsWidgets);
    expect(find.textContaining('đã chấm 🏃 Chạy bộ'), findsOneWidget);
    expect(find.text('15 phút trước'), findsOneWidget);

    // No sideways swipe from the feed
    await tester.dragFrom(center, const Offset(400, 0));
    await tester.pumpAndSettle();
    expect(find.text('Phân tích'), findsNothing);

    // 3. Pull down past the top of the feed to go back up to Home
    await tester.dragFrom(center, const Offset(0, 300));
    await tester.pumpAndSettle();
    expect(find.textContaining('HÔM NAY'), findsOneWidget);

    // 4. Analytics is to the left of Home, History to the right
    await tester.dragFrom(center, const Offset(400, 0));
    await tester.pumpAndSettle();
    expect(find.text('Phân tích'), findsOneWidget);

    await tester.dragFrom(center, const Offset(-400, 0));
    await tester.pumpAndSettle();
    await tester.dragFrom(center, const Offset(-400, 0));
    await tester.pumpAndSettle();
    expect(find.text('Lịch sử'), findsOneWidget);

    // 5. Back retraces: History → Home → Analytics → Home → Feed → Home
    Future<void> back() async {
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
    }

    await back();
    expect(find.textContaining('HÔM NAY'), findsOneWidget);
    await back();
    expect(find.text('Phân tích'), findsOneWidget);
    await back();
    expect(find.textContaining('HÔM NAY'), findsOneWidget);
    await back();
    expect(find.text('Bạn bè'), findsOneWidget);
    await back();
    expect(find.textContaining('HÔM NAY'), findsOneWidget);

    // 6. At Home with nothing left: first Back only shows a small hint
    expect(find.text('Bấm lần nữa để thoát'), findsOneWidget); // có sẵn, đang ẩn
    await back();
    expect(find.textContaining('HÔM NAY'), findsOneWidget);
    expect(
      tester.widget<AnimatedOpacity>(
        find.ancestor(of: find.text('Bấm lần nữa để thoát'), matching: find.byType(AnimatedOpacity)),
      ).opacity,
      1,
    );
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    // 4. Test Navigation to Add QR from Profile Sheet
    await tester.tap(find.byIcon(Icons.person_rounded).first);
    await tester.pumpAndSettle();

    expect(find.text('MÃ MỜI KẾT BẠN (SOC-01)'), findsOneWidget);
    expect(find.text('Mở Mã QR & Quét Bạn Bè'), findsOneWidget);

    await tester.tap(find.text('Mở Mã QR & Quét Bạn Bè'));
    await tester.pumpAndSettle();

    // Should navigate to AddQrPage
    expect(find.text('Chi Tiết Khoảnh Khắc'), findsOneWidget);
    expect(find.text('Mã QR của tôi'), findsOneWidget);
  });
}

