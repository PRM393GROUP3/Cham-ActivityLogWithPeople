import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'image_saver_io.dart' if (dart.library.js_interop) 'image_saver_web.dart' as impl;

/// Lưu ảnh PNG cho người dùng: Android → thư viện ảnh (album "Chấm"), Web → tải file xuống.
/// Trả về câu mô tả nơi đã lưu để hiển thị; ném [StateError] (thông báo tiếng Việt) nếu không lưu được.
typedef PngSaver = Future<String> Function(Uint8List bytes, {required String fileName});

final pngSaverProvider = Provider<PngSaver>((ref) => impl.savePng);
