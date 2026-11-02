import 'dart:convert';

import 'package:cham/features/account/data/account_api.dart';
import 'package:cham/features/activity_dial/domain/activity_log.dart';
import 'package:cham/features/activity_dial/presentation/activity_dial_controller.dart';
import 'package:cham/features/history/presentation/pages/history_page.dart';
import 'package:cham/features/sharing/data/share_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/fakes.dart';

ActivityLog log(String id, DateTime utc, {String type = 'coffee', String emoji = '☕', String name = 'Cà phê', String? note}) =>
    ActivityLog(id: id, eventTypeId: type, name: name, emoji: emoji, occurredAt: utc, note: note);

void main() {
  Future<ProviderContainer> pump(WidgetTester tester, List<ActivityLog> logs) async {
    SharedPreferences.setMockInitialValues({
      'cham_activity_logs_v1': jsonEncode(logs.map((l) => l.toJson()).toList()),
    });
    tester.view.physicalSize = const Size(420, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());
    final c = ProviderContainer(overrides: [
      shareApiProvider.overrideWithValue(FakeShareApi()),
      accountApiProvider.overrideWithValue(FakeAccountApi()),
    ]);
    addTearDown(c.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(container: c, child: const MaterialApp(home: HistoryPage())));
    await tester.pumpAndSettle();
    return c;
  }

  testWidgets('every record, newest first, grouped by VN day (HIS-01)', (tester) async {
    final now = DateTime.now().toUtc();
    await pump(tester, [
      log('today', now.subtract(const Duration(minutes: 5))),
      log('old', now.subtract(const Duration(days: 40)), type: 'water', emoji: '💧', name: 'Nước'),
    ]);

    expect(find.text('Hôm nay'), findsOneWidget);
    // Hôm nay đứng trên bản ghi 40 ngày trước.
    expect(
      tester.getTopLeft(find.text('Hôm nay')).dy,
      lessThan(tester.getTopLeft(find.byTooltip('Xóa bản ghi').last).dy),
    );
    expect(find.byTooltip('Xóa bản ghi'), findsNWidgets(2));
  });

  testWidgets('chips filter by type, note and visibility', (tester) async {
    final now = DateTime.now().toUtc();
    await pump(tester, [
      log('a', now.subtract(const Duration(minutes: 5)), note: 'Bạc xỉu'),
      log('b', now.subtract(const Duration(minutes: 9)), type: 'water', emoji: '💧', name: 'Nước'),
    ]);
    expect(find.byTooltip('Xóa bản ghi'), findsNWidgets(2));

    // Thanh chip cuộn ngang: kéo tới chip rồi mới bấm.
    final filters = find.descendant(of: find.byKey(const ValueKey('history-filters')), matching: find.byType(Scrollable));
    Future<void> tapChip(String label) async {
      final chip = find.descendant(of: find.byType(ChoiceChip), matching: find.text(label));
      await tester.scrollUntilVisible(chip, 80, scrollable: filters);
      await tester.ensureVisible(chip);
      await tester.pumpAndSettle();
      await tester.tap(chip);
      await tester.pumpAndSettle();
    }

    await tapChip('💧 Nước');
    expect(find.byTooltip('Xóa bản ghi'), findsOneWidget);

    await tester.drag(filters, const Offset(600, 0)); // về đầu thanh chip
    await tester.pumpAndSettle();
    await tapChip('Có ghi chú');
    expect(find.byTooltip('Xóa bản ghi'), findsOneWidget);
    expect(find.textContaining('Bạc xỉu'), findsOneWidget);

    await tester.drag(filters, const Offset(600, 0));
    await tester.pumpAndSettle();
    await tapChip('Công khai');
    expect(find.text('Chưa có lần chấm nào'), findsOneWidget);
  });

  testWidgets('deleting a record removes it (HIS-02)', (tester) async {
    final now = DateTime.now().toUtc();
    final c = await pump(tester, [
      log('t1', now.subtract(const Duration(minutes: 5))),
      log('t2', now.subtract(const Duration(minutes: 1))),
    ]);

    await tester.tap(find.byTooltip('Xóa bản ghi').first);
    await tester.pumpAndSettle();
    expect(c.read(activityDialControllerProvider).logs, hasLength(1));
    expect(find.byTooltip('Xóa bản ghi'), findsOneWidget);
  });
}
