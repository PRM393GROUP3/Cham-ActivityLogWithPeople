import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cham/features/account/data/account_api.dart';
import 'package:cham/features/friends/data/friends_api.dart';
import 'package:cham/features/friends/domain/qr_code_data.dart';
import 'package:cham/features/friends/presentation/pages/add_qr_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/fakes.dart';

const _demoQr = QrCodeData(displayName: 'Hà My (Tôi)', username: 'hamy_cham');

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
    expect(find.text('Chấm · @hamy_cham'), findsOneWidget);
    expect(find.text('Sao chép nickname'), findsOneWidget);

    // Tap "Sao chép nickname"
    await tester.ensureVisible(find.text('Sao chép nickname'));
    await tester.tap(find.text('Sao chép nickname'));
    await tester.pumpAndSettle();
    expect(find.text('Đã sao chép nickname: @hamy_cham'), findsOneWidget);

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
    expect(find.text('Nhập nickname'), findsOneWidget);

    // Toggle Flashlight
    await tester.tap(find.text('Bật đèn'));
    await tester.pumpAndSettle();
    expect(find.text('Tắt đèn'), findsOneWidget);

    // Open Manual code bottom sheet
    await tester.tap(find.text('Nhập nickname'));
    await tester.pumpAndSettle();
    expect(find.text('Nhập Nickname'), findsOneWidget);
    expect(find.text('Kết nối bạn bè'), findsOneWidget);

    // Dismiss bottom sheet
    Navigator.of(tester.element(find.text('Nhập Nickname'))).pop();
    await tester.pumpAndSettle();

    // Switch back to "Mã QR của tôi"
    await tester.tap(find.text('Mã QR của tôi'));
    await tester.pumpAndSettle();
    expect(find.text('Hà My (Tôi)'), findsOneWidget);
  });

  group('with the real account (SOC-01)', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    Widget app(FakeFriendsApi friendsApi, {bool online = true, String? username = 'toi.cham'}) => ProviderScope(
          overrides: [
            accountApiProvider.overrideWithValue(FakeAccountApi()
              ..online = online
              ..account = username == null ? testAccount : testAccount.copyWith(username: username)),
            friendsApiProvider.overrideWithValue(friendsApi),
          ],
          child: MaterialApp(
            routes: {
              '/friends': (_) => const Scaffold(body: Text('friends-route')),
              '/profile': (_) => const Scaffold(body: Text('profile-route')),
            },
            home: const AddQrPage(animateLaser: false, enableCamera: false),
          ),
        );

    testWidgets('shows the account username', (tester) async {
      tester.view.physicalSize = const Size(420, 920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(app(FakeFriendsApi()));
      await tester.pumpAndSettle();
      expect(find.text('@toi.cham'), findsOneWidget);
    });

    testWidgets('without a username there is no QR, only a way to set one', (tester) async {
      tester.view.physicalSize = const Size(420, 920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(app(FakeFriendsApi(), username: null));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('my_qr_card')), findsNothing);
      await tester.tap(find.text('Đặt nickname'));
      await tester.pumpAndSettle();
      expect(find.text('profile-route'), findsOneWidget);
    });

    testWidgets('asks to retry when offline on first use', (tester) async {
      await tester.pumpWidget(app(FakeFriendsApi(), online: false));
      await tester.pumpAndSettle();
      expect(find.textContaining('Cần kết nối mạng'), findsOneWidget);
      expect(find.text('Thử lại'), findsOneWidget);
    });

    testWidgets('entering a username makes friends immediately', (tester) async {
      tester.view.physicalSize = const Size(420, 920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());
      final friendsApi = FakeFriendsApi();

      await tester.pumpWidget(app(friendsApi));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Quét mã QR'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nhập nickname'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), ' @Khoa.Nguyen ');
      await tester.tap(find.text('Kết nối bạn bè'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Kết bạn'));
      await tester.pumpAndSettle();
      expect(find.text('Đã kết bạn với Bạn khoa.nguyen!'), findsOneWidget);
      expect(friendsApi.friends.single.id, 'f-khoa.nguyen', reason: 'manual entry is normalised');
    });
  });
}
