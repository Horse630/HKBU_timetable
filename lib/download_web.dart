import 'dart:convert';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

void savePng(Uint8List bytes, String filename) {
  final anchor = web.HTMLAnchorElement()
    ..href = 'data:image/png;base64,${base64Encode(bytes)}'
    ..download = filename;
  web.document.body?.appendChild(anchor);
  anchor.click();
  anchor.remove();
}

void openExternal(String url) {
  web.window.open(url, '_blank');
}
