import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cham/features/activity_dial/domain/activity_event_type.dart';
import 'package:cham/features/widgets/data/home_widget_bridge.dart';
import 'package:cham/features/widgets/presentation/pages/widget_selection_page.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('WidgetSelectionPage displays Small (2x2) and toggles to Medium (4x2)',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: WidgetSelectionPage(),
      ),
    );

    // Initial state: Small (2x2) is displayed
    expect(find.text('Cài Đặt'), findsOneWidget);
    expect(find.text('Nhỏ (2×2)'), findsOneWidget);
    expect(find.text('Vừa (4×2)'), findsOneWidget);
    expect(find.text('Chấm log'), findsOneWidget);
    expect(find.text('4 chấm hôm nay'), findsOneWidget);
    expect(find.text('Chạm trực tiếp ngoài màn hình chính'), findsOneWidget);
    expect(find.text('Thêm Widget'), findsOneWidget);

    // Tap on Vừa (4×2) tab
    await tester.tap(find.text('Vừa (4×2)'));
    await tester.pumpAndSettle();

    // Medium (4x2) is displayed
    expect(find.text('HÔM NAY'), findsOneWidget);
    expect(find.text('3/4'), findsOneWidget);
    expect(find.text('Cà phê'), findsOneWidget);
    expect(find.text('Chạy bộ'), findsOneWidget);
    expect(find.text('Chuỗi 12 ngày'), findsOneWidget);
    expect(find.text('Chạm trực tiếp trên màn hình chính để ghi nhận'), findsOneWidget);

    // Tap "+ Thêm Widget" button to open modal
    await tester.tap(find.text('Thêm Widget'));
    await tester.pumpAndSettle();

    expect(find.text('Thêm Widget Vừa (4×2)'), findsOneWidget);
    expect(find.text('Đã hiểu'), findsOneWidget);
  });

  test('HomeWidgetBridge saves and loads custom widget event types (WID-01)', () async {
    final types = ActivityEventType.defaultTypes;
    final water = types.firstWhere((t) => t.id == 'water');
    await HomeWidgetBridge.saveSmallType(water);

    final loadedSmall = await HomeWidgetBridge.loadSmallType(types);
    expect(loadedSmall.id, 'water');
    expect(loadedSmall.name, 'Nước');
    expect(loadedSmall.emoji, '💧');

    final customFour = types.skip(2).take(4).toList();
    await HomeWidgetBridge.saveMediumTypes(customFour);
    final loadedMedium = await HomeWidgetBridge.loadMediumTypes(types);
    expect(loadedMedium.map((e) => e.id).toList(), customFour.map((e) => e.id).toList());
  });
}
