abstract class KeyValueStore {
  String? getString(String key);

  void setString(String key, String value);

  String preferredLanguage();
}
