import 'dart:typed_data';

import 'package:gal/gal.dart';

Future<String> savePng(Uint8List bytes, {required String fileName}) async {
  if (!await Gal.hasAccess(toAlbum: true) && !await Gal.requestAccess(toAlbum: true)) {
    throw StateError('Chưa được cấp quyền lưu ảnh. Hãy cho phép trong cài đặt.');
  }
  try {
    await Gal.putImageBytes(bytes, album: 'Chấm', name: fileName);
  } on GalException catch (e) {
    throw StateError(switch (e.type) {
      GalExceptionType.accessDenied => 'Chưa được cấp quyền lưu ảnh. Hãy cho phép trong cài đặt.',
      GalExceptionType.notEnoughSpace => 'Máy không đủ dung lượng để lưu ảnh.',
      _ => 'Không lưu được ảnh.',
    });
  }
  return 'Đã lưu ảnh vào thư viện ảnh (album "Chấm").';
}
