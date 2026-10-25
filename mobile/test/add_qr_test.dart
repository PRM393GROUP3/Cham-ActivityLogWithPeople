import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cham/features/friends/presentation/pages/add_qr_page.dart';

void main() {
  testWidgets('AddQrPage renders My QR tab and switches to Scan QR tab correctly',
      (WidgetTester tester) async {
    // Set a realistic mobile viewport height so all card buttons are in view
    tester.view.physicalSize = const Size(420, 920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const MaterialApp(
        home: AddQrPage(animateLaser: false),
      ),
    );

    // Initial state: My QR tab
    expect(find.text('Chi Tiết Khoảnh Khắc'), findsOneWidget);
    expect(find.text('Mã QR của tôi'), findsOneWidget);
    expect(find.text('Quét mã QR'), findsOneWidget);
    expect(find.text('Hà My (Tôi)'), findsOneWidget);
    expect(find.text('@hamy_cham'), findsOneWidget);
    expect(
      find.text('Đưa mã này để bạn bè quét kết nối một chạm.'),
      findsOneWidget,
    );
    expect(find.text('Chia sẻ ảnh'), findsOneWidget);
    expect(find.text('Lưu vào máy'), findsOneWidget);

    // Tap "Lưu vào máy"
    await tester.ensureVisible(find.text('Lưu vào máy'));
    await tester.tap(find.text('Lưu vào máy'));
    await tester.pumpAndSettle();
    expect(find.text('Đã lưu ảnh mã QR vào thư viện ảnh!'), findsOneWidget);

    // Switch to "Quét mã QR" tab
    await tester.tap(find.text('Quét mã QR'));
    await tester.pumpAndSettle();

    // Verify scanner view components are visible
    expect(
      find.text('Căn chỉnh mã QR vào trong khung để kết nối một chạm.'),
      findsOneWidget,
    );
    expect(find.text('Bật đèn'), findsOneWidget);
    expect(find.text('Chọn ảnh'), findsOneWidget);
    expect(find.text('Nhập mã'), findsOneWidget);

    // Toggle Flashlight
    await tester.tap(find.text('Bật đèn'));
    await tester.pumpAndSettle();
    expect(find.text('Tắt đèn'), findsOneWidget);

    // Open Manual code bottom sheet
    await tester.tap(find.text('Nhập mã'));
    await tester.pumpAndSettle();
    expect(find.text('Nhập Mã Kết Bạn'), findsOneWidget);
    expect(find.text('Kết nối bạn bè'), findsOneWidget);

    // Dismiss bottom sheet
    Navigator.of(tester.element(find.text('Nhập Mã Kết Bạn'))).pop();
    await tester.pumpAndSettle();

    // Switch back to "Mã QR của tôi"
    await tester.tap(find.text('Mã QR của tôi'));
    await tester.pumpAndSettle();
    expect(find.text('Hà My (Tôi)'), findsOneWidget);
  });
}

