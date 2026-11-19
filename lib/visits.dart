import 'dart:convert';

import 'visits_fetch_stub.dart'
    if (dart.library.html) 'visits_fetch_web.dart'
    as visits_fetch;

/// GoatCounter's recorded total on 2026-11-19. The page never shows less than this.
const visitBase = 11790;

const visitCounterUrl = 'https://horse630.goatcounter.com/counter/TOTAL.json';

/// Reads the live GoatCounter total. Falls back to [visitBase] when that total
/// cannot be read yet, and never displays a number below the base.
Future<int> loadVisitCount() async {
  try {
    final body = await visits_fetch.fetchText(visitCounterUrl);
    return displayedVisits(parseVisitCount(body));
  } catch (_) {
    return visitBase;
  }
}

int displayedVisits(int? live) {
  if (live == null || live < visitBase) return visitBase;
  return live;
}

/// GoatCounter formats totals with a thousands separator, including a narrow space.
int? parseVisitCount(String body) {
  final Object? decoded;
  try {
    decoded = jsonDecode(body);
  } catch (_) {
    return null;
  }
  if (decoded is! Map) return null;
  final raw = decoded['count'];
  if (raw is int) return raw;
  if (raw is! String) return null;
  final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) return null;
  return int.tryParse(digits);
}

String formatVisitCount(int value) {
  final text = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < text.length; i++) {
    if (i > 0 && (text.length - i) % 3 == 0) buffer.write(',');
    buffer.write(text[i]);
  }
  return buffer.toString();
}
