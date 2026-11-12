import 'key_value_store.dart';

class MemoryStore implements KeyValueStore {
  final Map<String, String> _values = {};

  @override
  String? getString(String key) => _values[key];

  @override
  void setString(String key, String value) => _values[key] = value;

  @override
  String preferredLanguage() => 'en';
}

KeyValueStore createStore() => MemoryStore();
