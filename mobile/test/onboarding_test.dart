import 'dart:convert';

import 'package:cham/features/account/data/account_api.dart';
import 'package:cham/features/activity_dial/presentation/pages/activity_dial_page.dart';
import 'package:cham/features/friends/data/friends_api.dart';
import 'package:cham/features/onboarding/presentation/app_start_gate.dart';
import 'package:cham/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:cham/features/onboarding/presentation/startup_intro.dart';
import 'package:cham/features/sharing/data/share_api.dart';
import 'package:cham/features/social/data/feed_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/fakes.dart';

void main() {
  late FakeAccountApi accounts;

  Future<void> pump(WidgetTester tester, Map<String, Object> prefs) async {
    SharedPreferences.setMockInitialValues(prefs);
    tester.view.physicalSize = const Size(420, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());
    accounts = FakeAccountApi();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountApiProvider.overrideWithValue(accounts),
          friendsApiProvider.overrideWithValue(FakeFriendsApi()),
          feedApiProvider.overrideWithValue(FakeFeedApi([])),
          shareApiProvider.overrideWithValue(FakeShareApi()),
        ],
        child: const MaterialApp(home: AppStartGate()),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> next(WidgetTester tester) async {
    await tester.tap(find.text('Tiếp tục'));
    await tester.pumpAndSettle();
  }

  testWidgets('first launch shows the welcome; skipping lands on the dial and never asks again', (tester) async {
    await pump(tester, {});
    expect(find.text('Mỗi việc là một chấm'), findsOneWidget);

    await tester.tap(find.text('Bỏ qua'));
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingPage), findsNothing);
    expect(find.byType(ActivityDialPage), findsOneWidget);
    expect((await SharedPreferences.getInstance()).getBool('cham_onboarded_v1'), isTrue);
    expect(accounts.calls, 0); // bỏ qua thì không tạo tài khoản
  });

  testWidgets('people updating from an older version skip the welcome', (tester) async {
    await pump(tester, {'cham_account_v1': jsonEncode(testAccount.toJson())});
    expect(find.byType(OnboardingPage), findsNothing);
    expect(find.byType(ActivityDialPage), findsOneWidget);
  });

  testWidgets('the opening logo hands over to the dial, then gets out of the way', (tester) async {
    await pump(tester, {'cham_account_v1': jsonEncode(testAccount.toJson())});
    final intro = find.descendant(of: find.byType(StartupIntro), matching: find.byType(AbsorbPointer));
    expect(intro, findsNothing);
    expect(find.text('Chấm'), findsOneWidget); // chỉ còn tiêu đề Trang chủ, logo đã thu về nút +

    await tester.tap(find.byTooltip('Cài đặt'));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);
  });

  testWidgets('the last page sets the username, full name and emoji avatar, then opens the dial', (tester) async {
    await pump(tester, {});
    await next(tester);
    expect(find.text('Riêng tư là mặc định'), findsOneWidget);
    await next(tester);
    expect(find.text('Gần nhau bằng một chạm'), findsOneWidget);
    await next(tester);

    expect(find.text('Bạn bè sẽ gọi bạn là gì?'), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('onboarding-username')), 'Khoa.Nguyen');
    await tester.enterText(find.byKey(const ValueKey('onboarding-name')), 'Nguyễn Đăng Khoa');
    await tester.tap(find.byKey(const ValueKey('avatar-🐻')));
    await tester.pump();
    await tester.tap(find.text('Bắt đầu chấm'));
    await tester.pumpAndSettle();

    expect(accounts.profileUpdates.single.username, 'khoa.nguyen');
    expect(accounts.profileUpdates.single.displayName, 'Nguyễn Đăng Khoa');
    expect(accounts.profileUpdates.single.avatarEmoji, '🐻');
    expect(find.byType(ActivityDialPage), findsOneWidget);
  });

  testWidgets('username and full name are required, and the username must be well-formed', (tester) async {
    await pump(tester, {});
    for (var i = 0; i < 3; i++) {
      await next(tester);
    }
    await tester.tap(find.text('Bắt đầu chấm'));
    await tester.pumpAndSettle();
    expect(find.text('Hãy chọn một nickname.'), findsOneWidget);
    expect(find.text('Hãy nhập họ và tên.'), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('onboarding-username')), 'kh');
    await tester.enterText(find.byKey(const ValueKey('onboarding-name')), 'Khoa');
    await tester.tap(find.text('Bắt đầu chấm'));
    await tester.pumpAndSettle();
    expect(find.textContaining('3–20 ký tự'), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('onboarding-username')), 'khoa nguyễn!');
    expect(tester.widget<TextField>(find.byKey(const ValueKey('onboarding-username'))).controller!.text, 'khoanguyn');
    expect(accounts.calls, 0); // chưa hợp lệ thì chưa tạo tài khoản
  });

  testWidgets('a username someone else has stays on the page with an explanation', (tester) async {
    await pump(tester, {});
    accounts.takenUsernames.add('khoa');
    for (var i = 0; i < 3; i++) {
      await next(tester);
    }
    await tester.enterText(find.byKey(const ValueKey('onboarding-username')), 'Khoa');
    await tester.enterText(find.byKey(const ValueKey('onboarding-name')), 'Khoa');
    await tester.tap(find.text('Bắt đầu chấm'));
    await tester.pumpAndSettle();
    expect(find.text('Nickname này đã có người dùng.'), findsOneWidget);
    expect(find.byType(OnboardingPage), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('onboarding-username')), 'khoa_2');
    await tester.tap(find.text('Bắt đầu chấm'));
    await tester.pumpAndSettle();
    expect(accounts.profileUpdates.single.username, 'khoa_2');
    expect(find.byType(ActivityDialPage), findsOneWidget);
  });

  testWidgets('offline on the last page explains and still lets you continue later', (tester) async {
    await pump(tester, {});
    accounts.online = false;
    for (var i = 0; i < 3; i++) {
      await next(tester);
    }
    await tester.enterText(find.byKey(const ValueKey('onboarding-username')), 'khoa');
    await tester.enterText(find.byKey(const ValueKey('onboarding-name')), 'Khoa');
    await tester.tap(find.text('Bắt đầu chấm'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Chưa kết nối được'), findsOneWidget);
    await tester.tap(find.text('Để sau'));
    await tester.pumpAndSettle();
    expect(find.byType(ActivityDialPage), findsOneWidget);
  });
}
