import 'dart:js_interop';

import 'package:web/web.dart' as web;

Future<String> fetchText(String url) async {
  final response = await web.window.fetch(url.toJS).toDart;
  if (!response.ok) {
    throw StateError('Visit counter returned ${response.status}');
  }
  return (await response.text().toDart).toDart;
}
