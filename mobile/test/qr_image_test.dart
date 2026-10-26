import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cham/features/friends/data/qr_image_decoder.dart';
import 'package:cham/features/friends/domain/invite_qr.dart';
import 'package:cham/features/friends/presentation/widgets/custom_qr_view.dart';
import 'package:cham/features/friends/presentation/widgets/qr_scanner_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

/// Vẽ đúng widget QR của app thành PNG.
Future<Uint8List> renderAppQr(WidgetTester tester, String data) async {
  final key = GlobalKey();
  await tester.pumpWidget(MaterialApp(
    home: Center(child: RepaintBoundary(key: key, child: CustomQrView(data: data))),
  ));
  return (await tester.runAsync(() async {
    final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2);
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    return png!.buffer.asUint8List();
  }))!;
}

void main() {
  final code = InviteQr.encode('H4R7N2Q8ZK');

  group('decodeQrFromImage (Web + Android)', () {
    testWidgets('reads the app own QR from a screenshot-like PNG', (tester) async {
      final png = await renderAppQr(tester, code);
      expect(await tester.runAsync(() => decodeQrFromImage(png)), code);
    });

    testWidgets('reads it from a large, lossy JPEG like a phone photo', (tester) async {
      final png = await renderAppQr(tester, code);
      var photo = img.decodePng(png)!;
      // Đặt QR giữa một ảnh lớn màu xám nhạt, phóng to rồi nén JPEG chất lượng thấp.
      final canvas = img.Image(width: 3200, height: 2400)..clear(img.ColorRgb8(225, 220, 210));
      photo = img.copyResize(photo, width: 1400);
      img.compositeImage(canvas, photo, dstX: 900, dstY: 500);
      final jpeg = img.encodeJpg(canvas, quality: 55);
      expect(await tester.runAsync(() => decodeQrFromImage(jpeg)), code);
    });

    testWidgets('reads an inverted (light-on-dark) QR', (tester) async {
      final png = await renderAppQr(tester, code);
      final inverted = img.invert(img.decodePng(png)!);
      expect(await tester.runAsync(() => decodeQrFromImage(img.encodePng(inverted))), code);
    });

    testWidgets('returns null for a picture without a QR and for garbage bytes', (tester) async {
      final plain = img.Image(width: 400, height: 300)..clear(img.ColorRgb8(30, 120, 200));
      expect(await tester.runAsync(() => decodeQrFromImage(img.encodePng(plain))), isNull);
      expect(await tester.runAsync(() => decodeQrFromImage(Uint8List.fromList([1, 2, 3, 4, 5]))), isNull);
    });
  });

  testWidgets('"Chọn ảnh" decodes the picked image and hands the code over', (tester) async {
    final png = await renderAppQr(tester, code);
    final scanned = <String>[];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: QrScannerView(
            animateLaser: false,
            enableCamera: false,
            pickImage: () async => XFile.fromData(png, name: 'qr.png', mimeType: 'image/png'),
            onCodeScanned: (raw) async => scanned.add(raw),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('Chọn ảnh'));
    // Giải mã chạy qua compute (isolate thật) nên cần thời gian thật.
    for (var i = 0; i < 50 && scanned.isEmpty; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump();
    }
    expect(scanned, [code]);
  });

  testWidgets('"Chọn ảnh" with a picture that has no QR says so', (tester) async {
    final plain = img.encodePng(img.Image(width: 200, height: 200)..clear(img.ColorRgb8(255, 255, 255)));
    final scanned = <String>[];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: QrScannerView(
            animateLaser: false,
            enableCamera: false,
            pickImage: () async => XFile.fromData(plain, name: 'x.png'),
            onCodeScanned: (raw) async => scanned.add(raw),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('Chọn ảnh'));
    for (var i = 0; i < 50 && find.text('Không tìm thấy mã QR trong ảnh.').evaluate().isEmpty; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump();
    }
    expect(find.text('Không tìm thấy mã QR trong ảnh.'), findsOneWidget);
    expect(scanned, isEmpty);
  });
}
