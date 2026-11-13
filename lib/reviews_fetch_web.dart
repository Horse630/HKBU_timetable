import 'dart:js_interop';

import 'package:web/web.dart' as web;

Future<String> fetchReviewsCsv(String url) async {
  final response = await web.window.fetch(url.toJS).toDart;
  if (!response.ok) {
    throw StateError('Review sheet returned ${response.status}');
  }
  return (await response.text().toDart).toDart;
}

Future<void> submitReviewForm(String action, Map<String, String> fields) async {
  const frameName = 'hkbu-review-frame';
  web.document.getElementById(frameName)?.remove();
  final frame = web.HTMLIFrameElement()
    ..id = frameName
    ..name = frameName
    ..style.display = 'none';
  final form = web.HTMLFormElement()
    ..method = 'POST'
    ..action = action
    ..target = frameName
    ..style.display = 'none';
  web.document.body?.appendChild(frame);
  web.document.body?.appendChild(form);
  for (final field in fields.entries) {
    form.appendChild(
      web.HTMLInputElement()
        ..name = field.key
        ..value = field.value,
    );
  }
  form.submit();
  Future<void>.delayed(const Duration(seconds: 2), form.remove);
}
