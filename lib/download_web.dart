import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

bool get savesPngWithShareSheet {
  final agent = web.window.navigator.userAgent;
  final touch = web.window.navigator.maxTouchPoints > 0;
  final apple = agent.contains('iPhone') || agent.contains('iPad') || agent.contains('iPod') || (agent.contains('Macintosh') && touch);
  return apple || agent.contains('Android');
}

void savePng(Uint8List bytes, String filename) {
  final url = web.URL.createObjectURL(_pngFile(bytes, filename));
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = filename
    ..style.display = 'none';
  web.document.body?.appendChild(anchor);
  anchor.click();
  anchor.remove();
  web.URL.revokeObjectURL(url);
}

void presentPng(
  Uint8List bytes,
  String filename, {
  required String hint,
  required String saveLabel,
  required String closeLabel,
}) {
  final file = _pngFile(bytes, filename);
  final url = web.URL.createObjectURL(file);
  final overlay = web.HTMLDivElement();
  overlay.style
    ..position = 'fixed'
    ..inset = '0'
    ..zIndex = '2147483647'
    ..display = 'flex'
    ..flexDirection = 'column'
    ..alignItems = 'center'
    ..justifyContent = 'center'
    ..padding = '16px'
    ..boxSizing = 'border-box'
    ..backgroundColor = 'rgba(12, 60, 110, 0.96)'
    ..color = 'white'
    ..fontFamily = 'sans-serif';

  final image = web.HTMLImageElement()
    ..src = url
    ..alt = filename;
  image.style
    ..maxWidth = '100%'
    ..maxHeight = '68vh'
    ..objectFit = 'contain'
    ..backgroundColor = 'white'
    ..borderRadius = '8px';
  image.style.setProperty('-webkit-touch-callout', 'default');
  image.style.setProperty('-webkit-user-select', 'auto');

  final note = web.HTMLParagraphElement()..textContent = hint;
  note.style
    ..margin = '12px 0'
    ..fontSize = '14px'
    ..lineHeight = '1.4'
    ..textAlign = 'center'
    ..maxWidth = '420px';

  final actions = web.HTMLDivElement();
  actions.style
    ..display = 'flex'
    ..gap = '8px';

  final save = web.HTMLButtonElement()..textContent = saveLabel;
  final close = web.HTMLButtonElement()..textContent = closeLabel;
  for (final button in [save, close]) {
    button.style
      ..border = '0'
      ..borderRadius = '8px'
      ..padding = '10px 14px'
      ..fontSize = '15px'
      ..fontWeight = '700';
  }
  save.style
    ..backgroundColor = 'white'
    ..color = '#0C3C6E';
  close.style
    ..backgroundColor = 'transparent'
    ..color = 'white';

  var closed = false;
  void dismiss() {
    if (closed) return;
    closed = true;
    overlay.remove();
    web.URL.revokeObjectURL(url);
  }

  save.addEventListener(
    'click',
    ((web.Event event) {
      event.preventDefault();
      final data = web.ShareData(files: [file].toJS, title: filename);
      final navigator = web.window.navigator;
      if (!navigator.canShare(data)) {
        savePng(bytes, filename);
        return;
      }
      navigator.share(data).toDart.then((_) => dismiss(), onError: (Object error) {
        final message = error.toString();
        if (message.contains('AbortError') || message.contains('abort')) return;
      });
    }).toJS,
  );
  close.addEventListener('click', ((web.Event event) {
    event.preventDefault();
    dismiss();
  }).toJS);

  actions.append(save);
  actions.append(close);
  overlay.append(image);
  overlay.append(note);
  overlay.append(actions);
  web.document.body?.append(overlay);
}

void openExternal(String url) {
  final anchor = web.HTMLAnchorElement()..href = url;
  if (!url.startsWith('mailto:')) anchor.target = '_blank';
  web.document.body?.appendChild(anchor);
  anchor.click();
  anchor.remove();
}

web.File _pngFile(Uint8List bytes, String filename) {
  return web.File(
    [bytes.toJS].toJS,
    filename,
    web.FilePropertyBag(type: 'image/png', lastModified: DateTime.now().millisecondsSinceEpoch),
  );
}
