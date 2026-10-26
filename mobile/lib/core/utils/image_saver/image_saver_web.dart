import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

Future<String> savePng(Uint8List bytes, {required String fileName}) async {
  final blob = web.Blob([bytes.toJS].toJS, web.BlobPropertyBag(type: 'image/png'));
  final url = web.URL.createObjectURL(blob);
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = '$fileName.png';
  web.document.body!.append(anchor);
  anchor.click();
  anchor.remove();
  web.URL.revokeObjectURL(url);
  return 'Đã tải ảnh xuống ($fileName.png).';
}
