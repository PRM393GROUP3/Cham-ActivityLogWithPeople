import 'package:cham/features/friends/data/qr_image_decoder.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:zxing2/qrcode.dart';

/// Có thể chạy cả trong trình duyệt để kiểm tra bản Web (JS):
/// `flutter test --platform chrome test/qr_image_web_test.dart`
void main() {
  testWidgets('decodes a big phone-like photo, also when compiled to JS (web)', (tester) async {
    // Sinh QR mức H bằng chính zxing2, vẽ thành ảnh lớn rồi nén JPEG như ảnh chụp.
    final qr = Encoder.encode('CHAM:H4R7N2Q8ZK', ErrorCorrectionLevel.h);
    final m = qr.matrix!;
    const scale = 12, quiet = 4;
    final size = (m.width + quiet * 2) * scale;
    final image = img.Image(width: size, height: size)..clear(img.ColorRgb8(255, 255, 255));
    for (var y = 0; y < m.height; y++) {
      for (var x = 0; x < m.width; x++) {
        if (m.get(x, y) == 1) {
          img.fillRect(image,
              x1: (x + quiet) * scale, y1: (y + quiet) * scale,
              x2: (x + quiet + 1) * scale - 1, y2: (y + quiet + 1) * scale - 1,
              color: img.ColorRgb8(35, 31, 28));
        }
      }
    }
    expect(await tester.runAsync(() => decodeQrFromImage(img.encodePng(image))), 'CHAM:H4R7N2Q8ZK');
    final photo = img.encodeJpg(img.copyResize(image, width: 4000), quality: 60);
    expect(await tester.runAsync(() => decodeQrFromImage(photo)), 'CHAM:H4R7N2Q8ZK');
  });
}
