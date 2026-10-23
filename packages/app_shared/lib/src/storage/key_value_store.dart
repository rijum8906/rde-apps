import 'package:shared_preferences/shared_preferences.dart';

/// A small, testable abstraction over key/value persistence.
abstract interface class KeyValueStore {
  /// Reads the string stored at [key], or `null` when nothing is stored.
  Future<String?> readString(String key);

  /// Stores [value] at [key], replacing any previous value.
  Future<void> writeString(String key, String value);

  /// Removes the value stored at [key], if any.
  Future<void> remove(String key);

  /// Removes every value owned by this store.
  Future<void> clear();

  /// Lists the keys currently stored.
  Future<Set<String>> keys();
}

/// A [KeyValueStore] backed by `SharedPreferencesAsync`.
///
/// The async API reads from the platform on demand, which keeps multiple
/// isolates and the main isolate in sync.
final class PreferencesStore implements KeyValueStore {
  /// Creates a store, optionally wrapping an existing preferences instance.
  new({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;

  @override
  Future<String?> readString(String key) => _preferences.getString(key);

  @override
  Future<void> writeString(String key, String value) =>
      _preferences.setString(key, value);

  @override
  Future<void> remove(String key) => _preferences.remove(key);

  @override
  Future<void> clear() => _preferences.clear();

  @override
  Future<Set<String>> keys() => _preferences.getKeys();
}
