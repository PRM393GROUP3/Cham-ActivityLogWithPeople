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

  testWidgets('MainShellPage displays ActivityDial and swipes left to FeedPage',
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
            '/add-qr': (context) => const AddQrPage(animateLaser: false),
          },
          home: const MainShellPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Initial State: ActivityDialPage is visible
    expect(find.text('Chấm'), findsOneWidget);
    expect(find.textContaining('HÔM NAY'), findsOneWidget);

    // 2. Swipe Left from Main Screen to Feed Screen
    await tester.drag(find.byType(PageView), const Offset(-400, 0));
    await tester.pumpAndSettle();

    // Verify FeedPage shows friends and their Public records from the API
    expect(find.text('Tất cả'), findsOneWidget);
    expect(find.text('Minh Thư'), findsWidgets);
    expect(find.textContaining('đã chấm 🏃 Chạy bộ'), findsOneWidget);
    expect(find.text('15 phút trước'), findsOneWidget);

    // 3. Swipe Right back to ActivityDialPage
    await tester.drag(find.byType(PageView), const Offset(400, 0));
    await tester.pumpAndSettle();

    expect(find.textContaining('HÔM NAY'), findsOneWidget);

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

