import 'dart:convert';

import 'package:cham/features/account/data/account_api.dart';
import 'package:cham/features/activity_dial/presentation/pages/activity_dial_page.dart';
import 'package:cham/features/friends/data/friends_api.dart';
import 'package:cham/features/onboarding/presentation/app_start_gate.dart';
import 'package:cham/features/onboarding/presentation/pages/onboarding_page.dart';
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

  testWidgets('the last page sets the name and emoji avatar, then opens the dial', (tester) async {
    await pump(tester, {});
    await next(tester);
    expect(find.text('Riêng tư là mặc định'), findsOneWidget);
    await next(tester);
    expect(find.text('Gần nhau bằng một chạm'), findsOneWidget);
    await next(tester);

    expect(find.text('Bạn bè sẽ gọi bạn là gì?'), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('onboarding-name')), 'Khoa');
    await tester.tap(find.byKey(const ValueKey('avatar-🐻')));
    await tester.pump();
    await tester.tap(find.text('Bắt đầu chấm'));
    await tester.pumpAndSettle();

    expect(accounts.profileUpdates.single.displayName, 'Khoa');
    expect(accounts.profileUpdates.single.avatarEmoji, '🐻');
    expect(find.byType(ActivityDialPage), findsOneWidget);
  });

  testWidgets('offline on the last page explains and still lets you continue later', (tester) async {
    await pump(tester, {});
    accounts.online = false;
    for (var i = 0; i < 3; i++) {
      await next(tester);
    }
    await tester.enterText(find.byKey(const ValueKey('onboarding-name')), 'Khoa');
    await tester.tap(find.text('Bắt đầu chấm'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Chưa kết nối được'), findsOneWidget);
    await tester.tap(find.text('Để sau'));
    await tester.pumpAndSettle();
    expect(find.byType(ActivityDialPage), findsOneWidget);
  });
}
