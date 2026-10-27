import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:zxing2/qrcode.dart';

/// Đọc mã QR trong một ảnh (PNG, JPEG, WebP…). Trả về nội dung mã, hoặc `null` nếu không có.
///
/// Ảnh được giải nén và thu nhỏ bởi engine của Flutter (trên Web là trình duyệt) — nhanh hơn nhiều
/// so với giải nén bằng Dart; sau đó ZXing bản Dart thuần đọc mã, nên chạy được cả trên Web, nơi
/// `mobile_scanner` không hỗ trợ quét từ ảnh.
Future<String?> decodeQrFromImage(Uint8List encoded, {int maxSide = 1600}) async {
  final ({Uint8List rgba, int width, int height}) pixels;
  try {
    pixels = await _decodePixels(encoded, maxSide);
  } catch (_) {
    return null; // Không phải ảnh / định dạng không hỗ trợ.
  }
  // Trên Android chạy ở isolate riêng để không đứng giao diện; trên Web compute chạy tại chỗ.
  return compute(_decodeQrFromPixels, pixels);
}

Future<({Uint8List rgba, int width, int height})> _decodePixels(Uint8List encoded, int maxSide) async {
  // instantiateImageCodec có trên mọi nền tảng (ImageDescriptor chưa đủ trên Web). Chỉ giới hạn
  // chiều rộng, giữ tỷ lệ; ảnh nhỏ hơn thì giữ nguyên.
  final codec = await ui.instantiateImageCodec(encoded, targetWidth: maxSide, allowUpscaling: false);
  final image = (await codec.getNextFrame()).image;
  try {
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    return (rgba: data!.buffer.asUint8List(), width: image.width, height: image.height);
  } finally {
    image.dispose();
    codec.dispose();
  }
}

String? _decodeQrFromPixels(({Uint8List rgba, int width, int height}) p) =>
    decodeQrFromPixels(p.rgba, p.width, p.height);

/// Đọc mã QR từ mảng điểm ảnh RGBA (4 byte mỗi điểm).
@visibleForTesting
String? decodeQrFromPixels(Uint8List rgba, int width, int height) {
  final pixels = Int32List(width * height);
  for (var i = 0, j = 0; i < pixels.length; i++, j += 4) {
    pixels[i] = (rgba[j] << 16) | (rgba[j + 1] << 8) | rgba[j + 2]; // 0xRRGGBB
  }
  final LuminanceSource source = RGBLuminanceSource(width, height, pixels);
  final hints = DecodeHints()..put(DecodeHintType.tryHarder);

  // Hybrid hợp ảnh chụp (ánh sáng không đều), GlobalHistogram hợp ảnh chụp màn hình; thử cả QR đảo màu.
  for (final candidate in [source, InvertedLuminanceSource(source)]) {
    for (final bitmap in [
      BinaryBitmap(HybridBinarizer(candidate)),
      BinaryBitmap(GlobalHistogramBinarizer(candidate)),
    ]) {
      try {
        return QRCodeReader().decode(bitmap, hints: hints).text;
      } on ReaderException {
        // Thử cách tiếp theo.
      }
    }
  }
  return null;
}
