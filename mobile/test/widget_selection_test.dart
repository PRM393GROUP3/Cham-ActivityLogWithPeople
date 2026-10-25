import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cham/features/widgets/presentation/pages/widget_selection_page.dart';

void main() {
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
}
