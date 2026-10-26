import 'package:cham/features/account/data/account_api.dart';
import 'package:cham/features/account/presentation/account_controller.dart';
import 'package:cham/features/friends/data/friends_api.dart';
import 'package:cham/features/friends/domain/friend.dart';
import 'package:cham/features/friends/domain/invite_qr.dart';
import 'package:cham/features/friends/presentation/pages/add_qr_page.dart';
import 'package:cham/features/friends/presentation/pages/friends_page.dart';
import 'package:cham/features/friends/presentation/widgets/custom_qr_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/fakes.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('InviteQr', () {
    test('encodes with the CHAM: prefix and decodes it back', () {
      expect(InviteQr.encode('H4R7N2Q8ZK'), 'CHAM:H4R7N2Q8ZK');
      expect(InviteQr.decode('CHAM:H4R7N2Q8ZK'), 'H4R7N2Q8ZK');
    });

    test('accepts a bare code, any case and spaces (typed by hand)', () {
      expect(InviteQr.decode('h4r7 n2q8zk'), 'H4R7N2Q8ZK');
      expect(InviteQr.decode(' cham:h4r7n2q8zk '), 'H4R7N2Q8ZK');
    });

    test('rejects other QR codes and invalid characters', () {
      for (final raw in [null, '', 'https://example.com', 'CHAM:SHORT', 'H4R7N2Q8Z0', 'H4R7N2Q8ZKX', 'WIFI:S:x;;']) {
        expect(InviteQr.decode(raw), isNull, reason: '$raw');
      }
    });
  });

  testWidgets('My QR is a real QR code holding CHAM:<invite code>', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: CustomQrView(data: 'CHAM:H4R7N2Q8ZK'))));
    final qr = tester.widget<QrImageView>(find.byType(QrImageView));
    expect(qr.errorCorrectionLevel, QrErrorCorrectLevel.H, reason: 'logo overlay needs high error correction');
    expect(find.bySemanticsLabel('Mã QR kết bạn'), findsOneWidget);
  });

  group('AddQrPage with an account', () {
    late FakeAccountApi accountApi;
    late FakeFriendsApi friendsApi;

    Future<ProviderContainer> pump(WidgetTester tester) async {
      tester.view.physicalSize = const Size(420, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());
      accountApi = FakeAccountApi();
      friendsApi = FakeFriendsApi();
      final c = ProviderContainer(overrides: [
        accountApiProvider.overrideWithValue(accountApi),
        friendsApiProvider.overrideWithValue(friendsApi),
      ]);
      addTearDown(c.dispose);
      await tester.pumpWidget(UncontrolledProviderScope(
        container: c,
        child: MaterialApp(
          routes: {'/friends': (_) => const FriendsPage()},
          home: const AddQrPage(animateLaser: false, enableCamera: false),
        ),
      ));
      await tester.pumpAndSettle();
      return c;
    }

    Future<void> enterCode(WidgetTester tester, String code) async {
      await tester.tap(find.text('Quét mã QR'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nhập mã'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), code);
      await tester.tap(find.text('Kết nối bạn bè'));
      await tester.pumpAndSettle();
    }

    testWidgets('the QR encodes the account invite code', (tester) async {
      await pump(tester);
      expect(tester.widget<CustomQrView>(find.byType(CustomQrView)).data, 'CHAM:MYCODE');
    });

    testWidgets('a QR that is not a Chấm code is rejected without calling the API', (tester) async {
      await pump(tester);
      await enterCode(tester, 'https://example.com');
      expect(find.text('Đây không phải mã QR kết bạn của Chấm.'), findsOneWidget);
      expect(find.text('Kết bạn?'), findsNothing);
      expect(friendsApi.friends, isEmpty);
    });

    testWidgets('scanning your own code is rejected', (tester) async {
      final c = await pump(tester);
      await c.read(accountControllerProvider.notifier).rotateInviteCode(); // mã hợp lệ: B3T8WQ2N6M
      await tester.pumpAndSettle();
      await enterCode(tester, 'CHAM:B3T8WQ2N6M');
      expect(find.text('Đây là mã mời của chính bạn.'), findsOneWidget);
    });

    testWidgets('"Đổi mã mời" asks first, then shows the new code everywhere', (tester) async {
      final c = await pump(tester);
      await tester.ensureVisible(find.text('Đổi mã mời'));
      await tester.tap(find.text('Đổi mã mời'));
      await tester.pumpAndSettle();
      expect(find.text('Đổi mã mời?'), findsOneWidget);

      await tester.tap(find.text('Đổi mã'));
      await tester.pumpAndSettle();
      expect(c.read(accountControllerProvider).value!.inviteCode, 'B3T8WQ2N6M');
      expect(find.text('Mã mời: B3T8WQ2N6M'), findsOneWidget);
      expect(tester.widget<CustomQrView>(find.byType(CustomQrView)).data, 'CHAM:B3T8WQ2N6M');
    });

    testWidgets('the people button opens the friends list', (tester) async {
      await pump(tester);
      await tester.tap(find.byTooltip('Danh sách bạn bè'));
      await tester.pumpAndSettle();
      expect(find.text('Bạn bè (0)'), findsOneWidget);
    });
  });

  group('FriendsPage (SOC-02)', () {
    Future<FakeFriendsApi> pump(WidgetTester tester, List<Friend> friends) async {
      final api = FakeFriendsApi(friends);
      await tester.pumpWidget(ProviderScope(
        overrides: [
          accountApiProvider.overrideWithValue(FakeAccountApi()),
          friendsApiProvider.overrideWithValue(api),
        ],
        child: const MaterialApp(home: FriendsPage()),
      ));
      await tester.pumpAndSettle();
      return api;
    }

    testWidgets('lists friends with the date they became friends (VN time)', (tester) async {
      await pump(tester, [
        Friend(id: 'u2', displayName: 'Minh Thư', since: DateTime.utc(2026, 10, 20, 17, 30)), // 00:30 ngày 21 giờ VN
        Friend(id: 'u3', displayName: 'An', since: DateTime.utc(2026, 9, 1)),
      ]);
      expect(find.text('Bạn bè (2)'), findsOneWidget);
      expect(find.text('Minh Thư'), findsOneWidget);
      expect(find.text('Bạn bè từ 21/10/2026'), findsOneWidget);
    });

    testWidgets('removing a friend asks for confirmation and updates the list', (tester) async {
      final api = await pump(tester, [Friend(id: 'u2', displayName: 'Minh Thư', since: DateTime.utc(2026, 10, 1))]);

      await tester.tap(find.byTooltip('Huỷ kết bạn với Minh Thư'));
      await tester.pumpAndSettle();
      expect(find.text('Huỷ kết bạn với Minh Thư?'), findsOneWidget);

      await tester.tap(find.text('Giữ lại'));
      await tester.pumpAndSettle();
      expect(api.friends, hasLength(1));

      await tester.tap(find.byTooltip('Huỷ kết bạn với Minh Thư'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Huỷ kết bạn'));
      await tester.pumpAndSettle();
      expect(api.friends, isEmpty);
      expect(find.text('Bạn bè (0)'), findsOneWidget);
      expect(find.textContaining('Chưa có bạn bè nào'), findsOneWidget);
    });

    testWidgets('offline shows the error with a retry button', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          accountApiProvider.overrideWithValue(FakeAccountApi()..online = false),
          friendsApiProvider.overrideWithValue(FakeFriendsApi()),
        ],
        child: const MaterialApp(home: FriendsPage()),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Thử lại'), findsOneWidget);
    });
  });
}
