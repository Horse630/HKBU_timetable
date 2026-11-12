import 'package:web/web.dart' as web;

import 'key_value_store.dart';

class WebStore implements KeyValueStore {
  @override
  String? getString(String key) {
    try {
      return web.window.localStorage.getItem(key);
    } catch (_) {
      return null;
    }
  }

  @override
  void setString(String key, String value) {
    try {
      web.window.localStorage.setItem(key, value);
    } catch (_) {
      return;
    }
  }

  @override
  String preferredLanguage() {
    final language = web.window.navigator.language.toLowerCase();
    if (language.startsWith('zh')) return 'zh';
    return 'en';
  }
}

KeyValueStore createStore() => WebStore();
