import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cham/features/activity_dial/domain/activity_event_type.dart';
import 'package:cham/features/activity_dial/domain/activity_log.dart';
import 'package:cham/features/activity_dial/presentation/activity_dial_controller.dart';
import 'package:cham/features/activity_dial/presentation/pages/activity_dial_page.dart';
import 'package:cham/features/activity_dial/presentation/widgets/audience_selector_bar.dart';
import 'package:cham/features/sharing/data/share_api.dart';
import 'package:cham/features/sharing/data/share_outbox.dart';
import 'package:cham/features/account/data/account_api.dart';

import 'helpers/fakes.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AudienceSelectorBar Widget Tests', () {
    testWidgets('renders both tabs and handles switching', (tester) async {
      ShareVisibility current = ShareVisibility.private;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return AudienceSelectorBar(
                  selectedMode: current,
                  onChanged: (mode) => setState(() => current = mode),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Bạn bè'), findsOneWidget);
      expect(find.text('Chỉ mình tôi'), findsOneWidget);

      // Tap on "Bạn bè"
      await tester.tap(find.text('Bạn bè'));
      await tester.pumpAndSettle();
      expect(current, ShareVisibility.public);

      // Tap on "Chỉ mình tôi"
      await tester.tap(find.text('Chỉ mình tôi'));
      await tester.pumpAndSettle();
      expect(current, ShareVisibility.private);
    });
  });

  group('Locket-style Audience Mode in ActivityDialController', () {
    test('sticky preference and auto-sharing when in Friends mode', () async {
      final container = ProviderContainer(
        overrides: [
          accountApiProvider.overrideWithValue(FakeAccountApi()),
          shareApiProvider.overrideWithValue(FakeShareApi()),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(activityDialControllerProvider.notifier);
      await container.read(activityDialControllerProvider.notifier).syncShares();

      // Default is private
      expect(container.read(activityDialControllerProvider).audienceMode, ShareVisibility.private);

      final coffee = ActivityEventType.defaultTypes.first;

      // 1. Log in private mode -> creates private log
      final privateLog = await controller.quickLog(coffee);
      expect(privateLog.isPublic, isFalse);
      expect(privateLog.visibility, ShareVisibility.private);

      // 2. Switch to public (Friends) mode
      await controller.setAudienceMode(ShareVisibility.public);
      expect(container.read(activityDialControllerProvider).audienceMode, ShareVisibility.public);

      // 3. Log in friends mode -> automatically creates public log & queues outbox
      final publicLog = await controller.quickLog(coffee);
      expect(publicLog.isPublic, isTrue);
      expect(publicLog.visibility, ShareVisibility.public);

      final outbox = container.read(shareOutboxProvider);
      final ops = await outbox.load();
      expect(ops, isNotNull);
      expect(container.read(activityDialControllerProvider).logs.first.isPublic, isTrue);

      // 4. Verify sticky preference survives reload
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('cham_audience_mode'), 'public');
    });
  });

  group('ActivityDialPage with Audience Bar UI Tests', () {
    testWidgets('shows AudienceSelectorBar, logs according to mode, and offers override toast', (tester) async {
      tester.view.physicalSize = const Size(420, 920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            accountApiProvider.overrideWithValue(FakeAccountApi()),
            shareApiProvider.overrideWithValue(FakeShareApi()),
          ],
          child: const MaterialApp(
            home: ActivityDialPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Audience bar is displayed on ActivityDialPage
      expect(find.byType(AudienceSelectorBar), findsOneWidget);
      expect(find.text('Bạn bè'), findsOneWidget);
      expect(find.text('Chỉ mình tôi'), findsOneWidget);

      // Tap on "Bạn bè"
      await tester.tap(find.text('Bạn bè'));
      await tester.pumpAndSettle();

      // Tap on node (e.g. Cà phê)
      await tester.tap(find.text('Cà phê'));
      await tester.pumpAndSettle();

      // Feedback toast should display public status and offer "Giữ riêng tư" action
      expect(find.textContaining('Đã chia sẻ cho bạn bè 🌐'), findsOneWidget);
      expect(find.text('Giữ riêng tư'), findsOneWidget);

      // Tap "Giữ riêng tư" to override
      await tester.tap(find.text('Giữ riêng tư'));
      await tester.pumpAndSettle();
    });
  });
}

