import 'dart:typed_data';

import 'package:cham/core/utils/image_saver/image_saver.dart';
import 'package:cham/features/account/data/account_api.dart';
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
    test('encodes the username with the CHAM:@ prefix and decodes it back', () {
      expect(InviteQr.encode('khoa.nguyen'), 'CHAM:@khoa.nguyen');
      expect(InviteQr.decode('CHAM:@khoa.nguyen'), 'khoa.nguyen');
    });

    test('accepts a typed username with or without @, any case, spaces around', () {
      expect(InviteQr.decode(' @Khoa.Nguyen '), 'khoa.nguyen');
      expect(InviteQr.decode('khoa_2'), 'khoa_2');
      expect(InviteQr.decode(' cham:@KHOA '), 'khoa');
    });

    test('rejects other QR codes and invalid usernames', () {
      for (final raw in [null, '', '@', 'https://example.com', 'CHAM:@ab', 'khoa nguyen', 'khoá', 'WIFI:S:x;;']) {
        expect(InviteQr.decode(raw), isNull, reason: '$raw');
      }
    });
  });

  testWidgets('My QR is a real QR code holding CHAM:@<username>', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: CustomQrView(data: 'CHAM:@khoa.nguyen'))));
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
      accountApi = FakeAccountApi()..account = testAccount.copyWith(username: 'toi.cham');
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
      await tester.tap(find.text('Nhập tên'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), code);
      await tester.tap(find.text('Kết nối bạn bè'));
      await tester.pumpAndSettle();
    }

    testWidgets('the QR encodes the account username', (tester) async {
      await pump(tester);
      expect(tester.widget<CustomQrView>(find.byType(CustomQrView)).data, 'CHAM:@toi.cham');
    });

    testWidgets('a QR that is not a Chấm code is rejected without calling the API', (tester) async {
      await pump(tester);
      await enterCode(tester, 'https://example.com');
      expect(find.text('Đây không phải mã QR hay tên người dùng của Chấm.'), findsOneWidget);
      expect(find.text('Kết bạn?'), findsNothing);
      expect(friendsApi.friends, isEmpty);
    });

    testWidgets('scanning your own code or typing your own username is rejected', (tester) async {
      await pump(tester);
      await enterCode(tester, 'CHAM:@toi.cham');
      expect(find.text('Đây là tên người dùng của chính bạn.'), findsOneWidget);
      expect(find.text('Kết bạn?'), findsNothing);
    });

    testWidgets('an unknown username explains why nothing happened', (tester) async {
      await pump(tester);
      await enterCode(tester, '@nobody');
      await tester.tap(find.text('Kết bạn'));
      await tester.pumpAndSettle();
      expect(find.text('Không kết bạn được: Không tìm thấy ai có tên người dùng này.'), findsOneWidget);
      expect(friendsApi.friends, isEmpty);
    });

    testWidgets('"Lưu ảnh QR" saves a PNG of the QR named after the username', (tester) async {
      tester.view.physicalSize = const Size(420, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());
      final saved = <(Uint8List, String)>[];
      final c = ProviderContainer(overrides: [
        accountApiProvider.overrideWithValue(FakeAccountApi()..account = testAccount.copyWith(username: 'toi.cham')),
        friendsApiProvider.overrideWithValue(FakeFriendsApi()),
        pngSaverProvider.overrideWithValue((bytes, {required fileName}) async {
          saved.add((bytes, fileName));
          return 'saved-ok';
        }),
      ]);
      addTearDown(c.dispose);
      await tester.pumpWidget(UncontrolledProviderScope(
        container: c,
        child: const MaterialApp(home: AddQrPage(animateLaser: false, enableCamera: false)),
      ));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Lưu ảnh QR'));
      await tester.tap(find.text('Lưu ảnh QR'));
      // Chụp ảnh (toImage) là việc bất đồng bộ thật, chạy ngoài fake async của test.
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 500)));
      await tester.pumpAndSettle();

      expect(saved, hasLength(1));
      expect(saved.single.$2, 'cham-qr-toi.cham');
      expect(saved.single.$1.sublist(0, 4), [0x89, 0x50, 0x4E, 0x47], reason: 'PNG signature');
      expect(find.text('saved-ok'), findsOneWidget);
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
