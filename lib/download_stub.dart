import 'dart:typed_data';

bool get savesPngWithShareSheet => false;

void savePng(Uint8List bytes, String filename) {
  throw UnsupportedError('PNG download is available in the browser.');
}

void presentPng(
  Uint8List bytes,
  String filename, {
  required String hint,
  required String saveLabel,
  required String closeLabel,
}) {
  throw UnsupportedError('PNG download is available in the browser.');
}

void openExternal(String url) {}
