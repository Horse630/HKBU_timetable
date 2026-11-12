import 'dart:typed_data';

import 'download_stub.dart' if (dart.library.html) 'download_web.dart' as impl;

void savePng(Uint8List bytes, String filename) => impl.savePng(bytes, filename);

void openExternal(String url) => impl.openExternal(url);
