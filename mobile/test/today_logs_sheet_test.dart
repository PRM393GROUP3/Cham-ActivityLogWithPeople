import 'package:cham/features/account/data/account_api.dart';
import 'package:cham/features/activity_dial/domain/activity_log.dart';
import 'package:cham/features/activity_dial/presentation/activity_dial_controller.dart';
import 'package:cham/features/activity_dial/presentation/widgets/today_logs_sheet.dart';
import 'package:cham/features/sharing/data/share_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/fakes.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<(ProviderContainer, FakeShareApi)> pumpSheet(WidgetTester tester) async {
    tester.view.physicalSize = const Size(420, 920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final shareApi = FakeShareApi();
    final container = ProviderContainer(overrides: [
      shareApiProvider.overrideWithValue(shareApi),
      accountApiProvider.overrideWithValue(FakeAccountApi()),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: Scaffold(body: TodayLogsSheet())),
    ));
    await tester.pumpAndSettle();
    return (container, shareApi);
  }

  testWidgets('every record starts Private; toggling makes it Public and shows the send status',
      (tester) async {
    final (container, shareApi) = await pumpSheet(tester);

    // 4 bản ghi mẫu hôm nay, tất cả Riêng tư.
    expect(find.text('Riêng tư'), findsNWidgets(4));
    expect(find.text('Công khai'), findsNothing);

    await tester.tap(find.text('Riêng tư').first);
    await tester.pumpAndSettle();

    expect(find.text('Công khai'), findsOneWidget);
    expect(find.textContaining('Bạn bè đã thấy'), findsOneWidget);
    expect(shareApi.sent, hasLength(1));
    expect(container.read(activityDialControllerProvider).logs.where((l) => l.isPublic), hasLength(1));
  });

  testWidgets('a failed send is shown separately from "saved" and can be retried (NFR-03)', (tester) async {
    final (container, shareApi) = await pumpSheet(tester);
    shareApi.online = false;

    await tester.tap(find.text('Riêng tư').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('Đã lưu trên máy • Chưa gửi được'), findsOneWidget);
    expect(find.text('Thử lại'), findsOneWidget);

    shareApi.online = true;
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Bạn bè đã thấy'), findsOneWidget);
    expect(find.text('Thử lại'), findsNothing);
    expect(
      container.read(activityDialControllerProvider).logs.firstWhere((l) => l.isPublic).syncStatus,
      ShareSyncStatus.synced,
    );
  });
}
