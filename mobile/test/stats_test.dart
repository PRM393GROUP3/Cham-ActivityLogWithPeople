import 'dart:convert';

import 'package:cham/features/account/data/account_api.dart';
import 'package:cham/features/activity_dial/domain/activity_log.dart';
import 'package:cham/features/activity_dial/presentation/activity_dial_controller.dart';
import 'package:cham/features/sharing/data/share_api.dart';
import 'package:cham/features/stats/domain/activity_stats.dart';
import 'package:cham/features/stats/presentation/pages/stats_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/fakes.dart';

ActivityLog log(String id, DateTime utc, {String type = 'coffee', String emoji = '☕', String name = 'Cà phê'}) =>
    ActivityLog(id: id, eventTypeId: type, name: name, emoji: emoji, occurredAt: utc);

void main() {
  group('StatsRange (Vietnam time, week starts Monday)', () {
    test('day / week / month boundaries', () {
      final wed = DateTime.utc(2026, 10, 28); // Thứ Tư
      final week = StatsRange.containing(StatsPeriod.week, wed);
      expect(week.start, DateTime.utc(2026, 10, 26)); // Thứ Hai
      expect(week.dayCount, 7);

      final month = StatsRange.containing(StatsPeriod.month, wed);
      expect(month.dayCount, 31);
      expect(StatsRange.containing(StatsPeriod.month, DateTime.utc(2026, 2, 10)).dayCount, 28);

      final sunday = StatsRange.containing(StatsPeriod.week, DateTime.utc(2026, 11, 1));
      expect(sunday.start, DateTime.utc(2026, 10, 26), reason: 'Sunday belongs to the week that started Monday');
    });

    test('previous / next move by one period', () {
      final day = StatsRange.containing(StatsPeriod.day, DateTime.utc(2026, 10, 1));
      expect(day.previous().start, DateTime.utc(2026, 9, 30));
      expect(day.next().start, DateTime.utc(2026, 10, 2));
      final month = StatsRange.containing(StatsPeriod.month, DateTime.utc(2026, 1, 15));
      expect(month.previous().start, DateTime.utc(2025, 12, 1));
    });

    test('a record at 23:30 VN belongs to that VN day, not the UTC day (AC-08)', () {
      final day1 = StatsRange.containing(StatsPeriod.day, DateTime.utc(2026, 10, 1));
      expect(day1.contains(DateTime.utc(2026, 10, 1, 16, 30)), isTrue); // 23:30 ngày 1 giờ VN
      expect(day1.contains(DateTime.utc(2026, 10, 1, 17, 30)), isFalse); // 00:30 ngày 2 giờ VN
      expect(day1.contains(DateTime.utc(2026, 9, 30, 17, 0)), isTrue); // 00:00 ngày 1 giờ VN
    });
  });

  group('ActivityStats (STA-01)', () {
    final logs = [
      log('a', DateTime.utc(2026, 10, 26, 1, 0)), // T2 08:00 VN
      log('b', DateTime.utc(2026, 10, 26, 2, 30)), // T2 09:30
      log('c', DateTime.utc(2026, 10, 28, 1, 10), type: 'water', emoji: '💧', name: 'Nước'), // T4 08:10
      log('d', DateTime.utc(2026, 11, 1, 16, 0), type: 'water', emoji: '💧', name: 'Nước'), // CN 23:00
      log('e', DateTime.utc(2026, 11, 1, 17, 0)), // T2 tuần sau 00:00 → ngoài tuần
    ];
    final week = ActivityStats(StatsRange.containing(StatsPeriod.week, DateTime.utc(2026, 10, 27)), logs);

    test('counts only what was logged in the range, newest first', () {
      expect(week.total, 4);
      expect(week.logs.map((l) => l.id), ['d', 'c', 'b', 'a']);
    });

    test('counts per type, most frequent first', () {
      expect(week.byType.map((t) => (t.emoji, t.count)), [('☕', 2), ('💧', 2)]);
    });

    test('per weekday and per hour in VN time', () {
      expect(week.byDay, [2, 0, 1, 0, 0, 0, 1]);
      final hours = week.byHour;
      expect(hours[8], 2);
      expect(hours[9], 1);
      expect(hours[23], 1);
      expect(hours.reduce((a, b) => a + b), 4);
    });

    test('latest per type uses all history and the name logged at the time', () {
      final latest = latestByType(logs);
      expect(latest['coffee']!.id, 'e');
      expect(latest['water']!.id, 'd');
    });
  });

  group('StatsPage', () {
    Future<ProviderContainer> pump(WidgetTester tester, List<ActivityLog> logs) async {
      SharedPreferences.setMockInitialValues({
        'cham_activity_logs_v1': jsonEncode(logs.map((l) => l.toJson()).toList()),
      });
      tester.view.physicalSize = const Size(420, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());
      final c = ProviderContainer(overrides: [
        shareApiProvider.overrideWithValue(FakeShareApi()),
        accountApiProvider.overrideWithValue(FakeAccountApi()),
      ]);
      addTearDown(c.dispose);
      await tester.pumpWidget(UncontrolledProviderScope(container: c, child: const MaterialApp(home: StatsPage())));
      await tester.pumpAndSettle();
      return c;
    }

    testWidgets('shows today by type and hour; switching to Tuần / Tháng and back in time works', (tester) async {
      final now = DateTime.now().toUtc();
      await pump(tester, [
        log('t1', now.subtract(const Duration(minutes: 5))),
        log('t2', now.subtract(const Duration(minutes: 1)), type: 'water', emoji: '💧', name: 'Nước'),
        log('old', now.subtract(const Duration(days: 40))),
      ]);

      expect(find.textContaining('Hôm nay,'), findsOneWidget);
      expect(find.text('Theo loại sự kiện'), findsOneWidget);
      expect(find.text('Theo khung giờ'), findsOneWidget);
      expect(find.text('2'), findsWidgets); // tổng hôm nay
      expect(find.byTooltip('Sau').hitTestable(), findsOneWidget);
      expect(tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.chevron_right_rounded)).onPressed, isNull);

      await tester.tap(find.text('Tuần'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Tuần này'), findsOneWidget);
      expect(find.text('Theo ngày trong tuần'), findsOneWidget);
      expect(find.text('T2'), findsOneWidget);

      await tester.tap(find.text('Tháng'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Tháng này'), findsOneWidget);

      // Lùi 2 tháng: bản ghi "old" (40 ngày trước) nằm trong một trong hai tháng đó.
      await tester.tap(find.byTooltip('Trước'));
      await tester.pumpAndSettle();
      final oneBack = find.text('Chưa có lần chấm nào').evaluate().isEmpty;
      await tester.tap(find.byTooltip('Trước'));
      await tester.pumpAndSettle();
      final twoBack = find.text('Chưa có lần chấm nào').evaluate().isEmpty;
      expect(oneBack || twoBack, isTrue);
    });

    testWidgets('deleting from the history list updates the stats (HIS-02)', (tester) async {
      final now = DateTime.now().toUtc();
      final c = await pump(tester, [
        log('t1', now.subtract(const Duration(minutes: 5))),
        log('t2', now.subtract(const Duration(minutes: 1))),
      ]);
      expect(find.text('Các lần chấm'), findsOneWidget);

      await tester.tap(find.byTooltip('Xóa bản ghi').first);
      await tester.pumpAndSettle();
      expect(c.read(activityDialControllerProvider).logs, hasLength(1));
      expect(find.text('lần chấm · 1 loại sự kiện'), findsOneWidget);
    });

    testWidgets('empty range says so', (tester) async {
      await pump(tester, [log('old', DateTime.now().toUtc().subtract(const Duration(days: 3)))]);
      expect(find.text('Chưa có lần chấm nào'), findsOneWidget);
      expect(find.text('Theo loại sự kiện'), findsNothing);
    });
  });
}
