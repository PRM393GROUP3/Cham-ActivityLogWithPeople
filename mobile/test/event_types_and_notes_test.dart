import 'package:cham/features/account/data/account_api.dart';
import 'package:cham/features/activity_dial/domain/activity_event_type.dart';
import 'package:cham/features/activity_dial/domain/activity_log.dart';
import 'package:cham/features/activity_dial/domain/dial_layout.dart';
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

  group('layoutDial', () {
    List<ActivityEventType> types(int n) =>
        [for (var i = 0; i < n; i++) ActivityEventType.custom(id: 't$i', name: 'T$i', emoji: '⭐')];

    test('keeps the original 6 / 6 / 7 rings for 19 types and spreads each ring evenly', () {
      expect(dialRingSizes(19), [6, 6, 7]);
      final few = layoutDial(types(3));
      expect(few.map((t) => t.orbit), [1, 1, 1]);
      expect(few.map((t) => t.angleDegree), [-90, 30, 150]);
    });

    test('every type stays on a ring; extra types go to the sparsest ring first', () {
      expect(dialRingSizes(20), [6, 6, 8]);
      for (var n = 1; n <= maxEventTypes; n++) {
        final sizes = dialRingSizes(n);
        expect(sizes.reduce((a, b) => a + b), n);
        final placed = layoutDial(types(n));
        expect(placed, hasLength(n));
        expect(placed.every((t) => t.orbit >= 1 && t.orbit <= 3), isTrue);
      }
      final full = dialRingSizes(maxEventTypes);
      expect(full[2], greaterThan(full[1]));
      expect(full[1], greaterThan(full[0]));
      expect(full[2], lessThanOrEqualTo(17), reason: 'outer ring stays readable at ~390px');
    });

    test('dialRingOf matches where layoutDial puts each type', () {
      for (final n in [5, 19, 20, 30, maxEventTypes]) {
        final placed = layoutDial(types(n));
        for (var i = 0; i < n; i++) {
          expect(dialRingOf(i, n), placed[i].orbit);
        }
      }
    });
  });

  group('Event types in Settings (LOG-01, LOG-02, LOG-05)', () {
    Future<(ProviderContainer, ActivityDialController)> loaded() async {
      final c = makeContainer();
      c.read(activityDialControllerProvider);
      await settle();
      return (c, c.read(activityDialControllerProvider.notifier));
    }

    test('start with the 19 defaults, all on the dial', () async {
      final (c, _) = await loaded();
      final state = c.read(activityDialControllerProvider);
      expect(state.eventTypes.map((t) => t.id), ActivityEventType.defaultTypes.map((t) => t.id));
      expect(state.dialTypes, hasLength(19));
    });

    test('a new type goes on the dial (outer ring) and survives a restart', () async {
      final (c, ctrl) = await loaded();
      await ctrl.addEventType(emoji: ' 🏸 ', name: ' Cầu lông ');
      final dial = c.read(activityDialControllerProvider).dialTypes;
      expect(dial, hasLength(20));
      expect(dial.last.name, 'Cầu lông');
      expect(dial.last.orbit, 3);

      final reopened = makeContainer();
      reopened.read(activityDialControllerProvider);
      await settle();
      expect(reopened.read(activityDialControllerProvider).eventTypes.last.emoji, '🏸');
    });

    test('editing a default changes future taps only; old records keep their name', () async {
      final (c, ctrl) = await loaded();
      final coffee = c.read(activityDialControllerProvider).eventTypes.first;
      final oldLog = await ctrl.quickLog(coffee);

      await ctrl.updateEventType(coffee.id, emoji: '🧋', name: 'Trà sữa');
      final edited = c.read(activityDialControllerProvider).eventTypes.first;
      expect(edited.name, 'Trà sữa');
      expect(edited.icon, isNull, reason: 'a new emoji replaces the old Material icon');
      expect(c.read(activityDialControllerProvider).logs.firstWhere((l) => l.id == oldLog.id).name, 'Cà phê');

      final newLog = await ctrl.quickLog(edited);
      expect((newLog.emoji, newLog.name), ('🧋', 'Trà sữa'));

      final reopened = makeContainer();
      reopened.read(activityDialControllerProvider);
      await settle();
      expect(reopened.read(activityDialControllerProvider).eventTypes.first.name, 'Trà sữa');
    });

    test('renaming a default keeps its icon', () async {
      final (c, ctrl) = await loaded();
      await ctrl.updateEventType('coffee', emoji: '☕', name: 'Cà phê đen');
      expect(c.read(activityDialControllerProvider).eventTypes.first.icon, isNotNull);
    });

    test('deleting removes the button but keeps history; the last type cannot be deleted', () async {
      final (c, ctrl) = await loaded();
      final log = await ctrl.quickLog(c.read(activityDialControllerProvider).eventTypes.first);

      await ctrl.deleteEventType('coffee');
      final state = c.read(activityDialControllerProvider);
      expect(state.eventTypes.any((t) => t.id == 'coffee'), isFalse);
      expect(state.dialTypes, hasLength(18));
      expect(state.logs.any((l) => l.id == log.id), isTrue);

      for (final t in [...state.eventTypes.skip(1)]) {
        await ctrl.deleteEventType(t.id);
      }
      expect(c.read(activityDialControllerProvider).eventTypes, hasLength(1));
      expect(() => ctrl.deleteEventType(c.read(activityDialControllerProvider).eventTypes.single.id), throwsArgumentError);
    });

    test('reordering moves a type to another ring and is saved', () async {
      final (c, ctrl) = await loaded();
      await ctrl.reorderEventTypes(0, 18); // Cà phê: vòng trong → cuối vòng ngoài
      final state = c.read(activityDialControllerProvider);
      expect(state.eventTypes[18].id, 'coffee');
      expect(state.dialTypes.firstWhere((t) => t.id == 'coffee').orbit, 3);
      expect(state.dialTypes.firstWhere((t) => t.id == 'water').orbit, 1);

      final reopened = makeContainer();
      reopened.read(activityDialControllerProvider);
      await settle();
      expect(reopened.read(activityDialControllerProvider).eventTypes[18].id, 'coffee');
    });

    test('validates emoji and name', () async {
      final (c, ctrl) = await loaded();
      expect(() => ctrl.addEventType(emoji: '', name: 'X'), throwsArgumentError);
      expect(() => ctrl.addEventType(emoji: '🏸', name: '  '), throwsArgumentError);
      expect(() => ctrl.addEventType(emoji: '🏸', name: 'a' * 51), throwsArgumentError);
      expect(() => ctrl.updateEventType('coffee', emoji: '☕', name: ''), throwsArgumentError);
      expect(c.read(activityDialControllerProvider).eventTypes, hasLength(19));
    });

    test('allows at most $maxEventTypes types', () async {
      final (c, ctrl) = await loaded();
      for (var i = c.read(activityDialControllerProvider).eventTypes.length; i < maxEventTypes; i++) {
        await ctrl.addEventType(emoji: '⭐', name: 'Sự kiện $i');
      }
      expect(() => ctrl.addEventType(emoji: '⭐', name: 'Thừa'), throwsArgumentError);
      expect(c.read(activityDialControllerProvider).dialTypes, hasLength(maxEventTypes));
    });

    Future<ProviderContainer> pumpSettings(WidgetTester tester) async {
      tester.view.physicalSize = const Size(420, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());
      final c = makeContainer();
      await tester.pumpWidget(UncontrolledProviderScope(
        container: c,
        child: const MaterialApp(home: EventTypesPage()),
      ));
      await tester.pumpAndSettle();
      return c;
    }

    testWidgets('Settings lists the 19 defaults with their ring position', (tester) async {
      await pumpSettings(tester);
      expect(find.text('☕ Cà phê'), findsOneWidget);
      expect(find.text('🚲 Đạp xe'), findsOneWidget);
      expect(find.text('Vòng trong'), findsNWidgets(6));
      expect(find.text('Vòng giữa'), findsNWidgets(6));
      expect(find.text('Vòng ngoài'), findsNWidgets(7));
    });

    testWidgets('add: picking an emoji fills its default name', (tester) async {
      final c = await pumpSettings(tester);
      await tester.tap(find.text('Thêm loại sự kiện'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const ValueKey('emoji-🏃')));
      await tester.tap(find.byKey(const ValueKey('emoji-🏃')));
      await tester.pump();
      expect(tester.widget<TextField>(find.byKey(const ValueKey('name-field'))).controller!.text, 'Chạy bộ');

      await tester.tap(find.text('Lưu'));
      await tester.pumpAndSettle();
      expect(c.read(activityDialControllerProvider).eventTypes.last.emoji, '🏃');
      expect(find.text('Vòng ngoài'), findsNWidgets(8));
    });

    testWidgets('edit a default from its pencil button', (tester) async {
      final c = await pumpSettings(tester);
      await tester.tap(find.byTooltip('Sửa Cà phê'));
      await tester.pumpAndSettle();
      expect(find.text('Sửa loại sự kiện'), findsOneWidget);

      await tester.enterText(find.byKey(const ValueKey('name-field')), 'Cà phê sữa đá');
      await tester.tap(find.text('Lưu'));
      await tester.pumpAndSettle();
      expect(find.text('☕ Cà phê sữa đá'), findsOneWidget);
      expect(c.read(activityDialControllerProvider).eventTypes.first.name, 'Cà phê sữa đá');
    });

    testWidgets('delete asks for confirmation', (tester) async {
      final c = await pumpSettings(tester);
      await tester.tap(find.byTooltip('Xoá Nước'));
      await tester.pumpAndSettle();
      expect(find.text('Xoá 💧 Nước?'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Xoá'));
      await tester.pumpAndSettle();
      expect(find.text('💧 Nước'), findsNothing);
      expect(c.read(activityDialControllerProvider).eventTypes, hasLength(18));
    });

    testWidgets('a 20th type appears on the dial; tapping it logs it', (tester) async {
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
      expect(find.text('Sự kiện khác'), findsNothing);
      expect(find.text('Cầu lông'), findsOneWidget);

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
