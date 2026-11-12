import 'key_value_store.dart';
import 'storage_stub.dart' if (dart.library.html) 'storage_web.dart' as impl;

KeyValueStore createStore() => impl.createStore();
