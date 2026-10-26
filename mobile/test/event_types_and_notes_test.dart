import 'package:cham/features/account/data/account_api.dart';
import 'package:cham/features/activity_dial/domain/activity_event_type.dart';
import 'package:cham/features/activity_dial/domain/activity_log.dart';
import 'package:cham/features/activity_dial/presentation/activity_dial_controller.dart';
import 'package:cham/features/activity_dial/presentation/pages/activity_dial_page.dart';
import 'package:cham/features/activity_dial/presentation/pages/event_types_page.dart';
import 'package:cham/features/activity_dial/presentation/widgets/today_logs_sheet.dart';
import 'package:cham/features/sharing/data/share_api.dart';
import 'package:cham/features/sharing/data/share_outbox.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/fakes.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  late FakeShareApi shareApi;

  ProviderContainer makeContainer() {
    shareApi = FakeShareApi();
    final c = ProviderContainer(overrides: [
      shareApiProvider.overrideWithValue(shareApi),
      accountApiProvider.overrideWithValue(FakeAccountApi()),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  group('Custom event types (LOG-01, LOG-02, LOG-05)', () {
    test('are added after the 19 defaults and survive an app restart', () async {
      final c = makeContainer();
      c.read(activityDialControllerProvider);
      await settle();

      await c.read(activityDialControllerProvider.notifier).addEventType(emoji: ' 🏸 ', name: ' Cầu lông ');
      final state = c.read(activityDialControllerProvider);
      expect(state.dialTypes, hasLength(19));
      expect(state.customTypes.single.name, 'Cầu lông');
      expect(state.customTypes.single.emoji, '🏸');
      expect(state.customTypes.single.isCustom, isTrue);

      final reopened = makeContainer();
      reopened.read(activityDialControllerProvider);
      await settle();
      expect(reopened.read(activityDialControllerProvider).customTypes.map((t) => t.name), ['Cầu lông']);
    });

    test('require an emoji and a name of at most 50 characters', () async {
      final c = makeContainer();
      c.read(activityDialControllerProvider);
      await settle();
      final ctrl = c.read(activityDialControllerProvider.notifier);

      expect(() => ctrl.addEventType(emoji: '', name: 'X'), throwsArgumentError);
      expect(() => ctrl.addEventType(emoji: '🏸', name: '  '), throwsArgumentError);
      expect(() => ctrl.addEventType(emoji: '🏸', name: 'a' * 51), throwsArgumentError);
      expect(c.read(activityDialControllerProvider).customTypes, isEmpty);
    });

    test('a tap on a custom type creates a Private record like the defaults', () async {
      final c = makeContainer();
      c.read(activityDialControllerProvider);
      await settle();
      final ctrl = c.read(activityDialControllerProvider.notifier);
      final type = await ctrl.addEventType(emoji: '🏸', name: 'Cầu lông');

      final log = await ctrl.quickLog(type);
      expect(log.emoji, '🏸');
      expect(log.eventTypeId, type.id);
      expect(log.visibility, ShareVisibility.private);
    });

    testWidgets('Settings page: picking an emoji fills its default name, Save adds it', (tester) async {
      final c = makeContainer();
      await tester.pumpWidget(UncontrolledProviderScope(
        container: c,
        child: const MaterialApp(home: EventTypesPage()),
      ));
      await tester.pumpAndSettle();
      expect(find.textContaining('Chưa có loại sự kiện nào'), findsOneWidget);

      await tester.tap(find.text('Thêm loại sự kiện'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const ValueKey('emoji-🏃')));
      await tester.tap(find.byKey(const ValueKey('emoji-🏃')));
      await tester.pump();
      expect(tester.widget<TextField>(find.byKey(const ValueKey('name-field'))).controller!.text, 'Chạy bộ');

      await tester.tap(find.text('Lưu'));
      await tester.pumpAndSettle();
      expect(find.text('Chạy bộ'), findsOneWidget);
      expect(c.read(activityDialControllerProvider).customTypes.single.emoji, '🏃');
    });

    testWidgets('home screen shows "Sự kiện của bạn" and tapping logs it', (tester) async {
      tester.view.physicalSize = const Size(420, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final c = makeContainer();
      c.read(activityDialControllerProvider);
      await tester.pumpAndSettle();
      await c.read(activityDialControllerProvider.notifier).addEventType(emoji: '🏸', name: 'Cầu lông');

      await tester.pumpWidget(UncontrolledProviderScope(
        container: c,
        child: const MaterialApp(home: ActivityDialPage()),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Sự kiện của bạn'), findsOneWidget);

      final before = c.read(activityDialControllerProvider).logs.length;
      await tester.tap(find.text('Cầu lông'));
      await tester.pumpAndSettle();
      expect(c.read(activityDialControllerProvider).logs.length, before + 1);
      expect(c.read(activityDialControllerProvider).logs.first.name, 'Cầu lông');
    });
  });

  group('Notes (NOTE-01)', () {
    test('round-trips through JSON and is optional', () {
      final log = ActivityLog(
        id: 'a',
        eventTypeId: 'coffee',
        name: 'Cà phê',
        emoji: '☕',
        occurredAt: DateTime.utc(2026, 10, 1),
        note: 'Ly thứ 2\nhơi đắng',
      );
      expect(ActivityLog.fromJson(log.toJson()).note, 'Ly thứ 2\nhơi đắng');
      expect(log.toJson().containsKey('note'), isTrue);
      expect(log.copyWith(note: () => null).toJson().containsKey('note'), isFalse);
    });

    test('setNote saves locally, blank clears it, and nothing is sent to the server', () async {
      final c = makeContainer();
      c.read(activityDialControllerProvider);
      await settle();
      final ctrl = c.read(activityDialControllerProvider.notifier);
      final log = await ctrl.quickLog(ActivityEventType.defaultTypes.first);
      await ctrl.setVisibility(log.id, ShareVisibility.public);
      shareApi.sent.clear();

      await ctrl.setNote(log.id, 'Ghi chú riêng');
      ActivityLog current() => c.read(activityDialControllerProvider).logs.firstWhere((l) => l.id == log.id);
      expect(current().note, 'Ghi chú riêng');
      expect(current().syncStatus, ShareSyncStatus.synced);
      expect(shareApi.sent, isEmpty, reason: 'notes stay on the device even for Public records');
      expect(await ShareOutbox().load(), isEmpty);

      await ctrl.setNote(log.id, '   ');
      expect(current().note, isNull);
    });

    testWidgets('tapping the note icon opens the paper; leaving saves the note', (tester) async {
      tester.view.physicalSize = const Size(420, 920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final c = makeContainer();
      await tester.pumpWidget(UncontrolledProviderScope(
        container: c,
        child: const MaterialApp(home: Scaffold(body: TodayLogsSheet())),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Viết ghi chú').first);
      await tester.pumpAndSettle();
      expect(find.text('Viết ghi chú cho sự kiện này…'), findsOneWidget);

      await tester.enterText(find.byKey(const ValueKey('note-field')), 'Uống với An\nở quán quen');
      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.text('📝 Uống với An'), findsOneWidget);
      expect(find.byTooltip('Xem / sửa ghi chú'), findsOneWidget);
      expect(c.read(activityDialControllerProvider).logs.where((l) => l.hasNote).single.note, 'Uống với An\nở quán quen');
    });

    testWidgets('the Lưu button saves and closes the paper', (tester) async {
      tester.view.physicalSize = const Size(420, 920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final c = makeContainer();
      await tester.pumpWidget(UncontrolledProviderScope(
        container: c,
        child: const MaterialApp(home: Scaffold(body: TodayLogsSheet())),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Viết ghi chú').first);
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('note-field')), 'Ngon');
      await tester.tap(find.text('Lưu'));
      await tester.pumpAndSettle();

      expect(find.text('📝 Ngon'), findsOneWidget);
    });
  });
}
