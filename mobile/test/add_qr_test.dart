import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cham/features/account/data/account_api.dart';
import 'package:cham/features/friends/data/friends_api.dart';
import 'package:cham/features/friends/domain/qr_code_data.dart';
import 'package:cham/features/friends/presentation/pages/add_qr_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/fakes.dart';

const _demoQr = QrCodeData(displayName: 'Hà My (Tôi)', username: '@hamy_cham', inviteCode: 'CHAM-8F3K9M');

void main() {
  testWidgets('AddQrPage renders My QR tab and switches to Scan QR tab correctly',
      (WidgetTester tester) async {
    // Set a realistic mobile viewport height so all card buttons are in view
    tester.view.physicalSize = const Size(420, 920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: AddQrPage(animateLaser: false, enableCamera: false, qrData: _demoQr),
        ),
      ),
    );

    // Initial state: My QR tab
    expect(find.text('Chi Tiết Khoảnh Khắc'), findsOneWidget);
    expect(find.text('Mã QR của tôi'), findsOneWidget);
    expect(find.text('Quét mã QR'), findsOneWidget);
    expect(find.text('Hà My (Tôi)'), findsOneWidget);
    expect(find.text('@hamy_cham'), findsOneWidget);
    expect(
      find.text('Đưa mã này để bạn bè quét kết nối một chạm.'),
      findsOneWidget,
    );
    expect(find.text('Sao chép mã'), findsOneWidget);
    expect(find.text('Đổi mã mời'), findsNothing, reason: 'fixed demo data has no account to rotate');

    // Tap "Sao chép mã"
    await tester.ensureVisible(find.text('Sao chép mã'));
    await tester.tap(find.text('Sao chép mã'));
    await tester.pumpAndSettle();
    expect(find.text('Đã sao chép mã mời: CHAM-8F3K9M'), findsOneWidget);

    // Switch to "Quét mã QR" tab
    await tester.tap(find.text('Quét mã QR'));
    await tester.pumpAndSettle();

    // Verify scanner view components are visible
    expect(
      find.text('Căn chỉnh mã QR vào trong khung để kết nối một chạm.'),
      findsOneWidget,
    );
    expect(find.text('Bật đèn'), findsOneWidget);
    expect(find.text('Chọn ảnh'), findsOneWidget);
    expect(find.text('Nhập mã'), findsOneWidget);

    // Toggle Flashlight
    await tester.tap(find.text('Bật đèn'));
    await tester.pumpAndSettle();
    expect(find.text('Tắt đèn'), findsOneWidget);

    // Open Manual code bottom sheet
    await tester.tap(find.text('Nhập mã'));
    await tester.pumpAndSettle();
    expect(find.text('Nhập Mã Kết Bạn'), findsOneWidget);
    expect(find.text('Kết nối bạn bè'), findsOneWidget);

    // Dismiss bottom sheet
    Navigator.of(tester.element(find.text('Nhập Mã Kết Bạn'))).pop();
    await tester.pumpAndSettle();

    // Switch back to "Mã QR của tôi"
    await tester.tap(find.text('Mã QR của tôi'));
    await tester.pumpAndSettle();
    expect(find.text('Hà My (Tôi)'), findsOneWidget);
  });

  group('with the real account (SOC-01)', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    Widget app(FakeFriendsApi friendsApi, {bool online = true}) => ProviderScope(
          overrides: [
            accountApiProvider.overrideWithValue(FakeAccountApi()..online = online),
            friendsApiProvider.overrideWithValue(friendsApi),
          ],
          child: MaterialApp(
            routes: {'/friends': (_) => const Scaffold(body: Text('friends-route'))},
            home: const AddQrPage(animateLaser: false, enableCamera: false),
          ),
        );

    testWidgets('shows the invite code of the anonymous account', (tester) async {
      tester.view.physicalSize = const Size(420, 920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(app(FakeFriendsApi()));
      await tester.pumpAndSettle();
      expect(find.text('Mã mời: MYCODE'), findsOneWidget);
    });

    testWidgets('asks to retry when offline on first use', (tester) async {
      await tester.pumpWidget(app(FakeFriendsApi(), online: false));
      await tester.pumpAndSettle();
      expect(find.textContaining('Cần kết nối mạng'), findsOneWidget);
      expect(find.text('Thử lại'), findsOneWidget);
    });

    testWidgets('entering an invite code makes friends immediately', (tester) async {
      tester.view.physicalSize = const Size(420, 920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());
      final friendsApi = FakeFriendsApi();

      await tester.pumpWidget(app(friendsApi));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Quét mã QR'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nhập mã'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'h4r7 n2q8zk');
      await tester.tap(find.text('Kết nối bạn bè'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Kết bạn'));
      await tester.pumpAndSettle();
      expect(find.text('Đã kết bạn với Bạn H4R7N2Q8ZK!'), findsOneWidget);
      expect(friendsApi.friends.single.id, 'f-H4R7N2Q8ZK', reason: 'manual entry is normalised');
    });
  });
}
