import 'dart:js_interop';

import 'package:web/web.dart' as web;

Future<String> fetchReviewsCsv(String url) async {
  final response = await web.window.fetch(url.toJS).toDart;
  if (!response.ok) {
    throw StateError('Review sheet returned ${response.status}');
  }
  return (await response.text().toDart).toDart;
}
