import 'dart:convert';

import 'package:app_shared/app_shared.dart';
import 'package:speed_test/features/speed_test/domain/entities/speed_test_profile.dart';

/// Loads and persists the selected test profile.
///
/// The theme is not stored here: it is owned by the shared
/// `AppThemeController` and persisted by `app_theme`'s `ThemeStore`.
final class SettingsRepository {
  /// Creates a repository backed by the supplied store.
  new(this._store);

  /// The key that owns the app's own preferences.
  static const String storageKey = 'speed_test.settings';

  final KeyValueStore _store;

  /// Reads the stored profile, defaulting to balanced.
  ///
  /// Missing or corrupt payloads are never fatal.
  Future<SpeedTestProfile> load() async {
    try {
      final raw = await _store.readString(storageKey);
      if (raw == null) {
        return SpeedTestProfile.balanced;
      }
      final decoded = jsonDecode(raw);
      if (decoded is! Map<Object?, Object?>) {
        return SpeedTestProfile.balanced;
      }
      return SpeedTestProfile.fromName(decoded['profile']);
    } on Object {
      return SpeedTestProfile.balanced;
    }
  }

  /// Persists [profile], ignoring storage failures.
  Future<void> save(SpeedTestProfile profile) async {
    try {
      await _store.writeString(
        storageKey,
        jsonEncode(<String, Object?>{'profile': profile.name}),
      );
    } on Object {
      // Preferences are best-effort; the in-memory state stays authoritative.
    }
  }

  /// Removes the stored profile.
  Future<void> reset() async {
    try {
      await _store.remove(storageKey);
    } on Object {
      // Best-effort, as above.
    }
  }
}
