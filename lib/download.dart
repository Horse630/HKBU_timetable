import 'dart:typed_data';

import 'download_stub.dart' if (dart.library.html) 'download_web.dart' as impl;

String timetablePngName(DateTime time) {
  String two(int value) => value.toString().padLeft(2, '0');
  return 'hkbu-timetable-${time.year}-${two(time.month)}-${two(time.day)}-${two(time.hour)}${two(time.minute)}.png';
}

bool get savesPngWithShareSheet => impl.savesPngWithShareSheet;

void savePng(Uint8List bytes, String filename) => impl.savePng(bytes, filename);

void presentPng(
  Uint8List bytes,
  String filename, {
  required String hint,
  required String saveLabel,
  required String closeLabel,
}) => impl.presentPng(bytes, filename, hint: hint, saveLabel: saveLabel, closeLabel: closeLabel);

void openExternal(String url) => impl.openExternal(url);
