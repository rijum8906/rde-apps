import 'dart:convert';

import 'package:app_shared/app_shared.dart';
import 'package:core/core.dart';

/// Loads and persists the calculator's trigonometric unit.
///
/// The theme is not stored here: it is owned by the shared
/// `AppThemeController` and persisted by `app_theme`'s `ThemeStore`.
final class SettingsRepository {
  /// Creates a repository backed by `store`.
  new(this._store);

  /// The key that owns the calculator's own preferences.
  static const String storageKey = 'calculator.settings';

  final KeyValueStore _store;

  /// Reads the stored unit, defaulting to degrees.
  ///
  /// Missing or corrupt payloads are never fatal, and values written by older
  /// versions (which also stored theme fields) are read for `angleMode` only.
  Future<AngleMode> load() async {
    try {
      final raw = await _store.readString(storageKey);
      if (raw == null) {
        return AngleMode.degrees;
      }
      final decoded = jsonDecode(raw);
      if (decoded is! Map<Object?, Object?>) {
        return AngleMode.degrees;
      }
      final name = decoded['angleMode'];
      for (final mode in AngleMode.values) {
        if (mode.name == name) {
          return mode;
        }
      }
      return AngleMode.degrees;
    } on Object {
      return AngleMode.degrees;
    }
  }

  /// Persists [mode], ignoring storage failures.
  Future<void> save(AngleMode mode) async {
    try {
      await _store.writeString(
        storageKey,
        jsonEncode(<String, Object?>{'angleMode': mode.name}),
      );
    } on Object {
      // Preferences are best-effort; the in-memory state stays authoritative.
    }
  }

  /// Removes the stored unit.
  Future<void> reset() async {
    try {
      await _store.remove(storageKey);
    } on Object {
      // Best-effort, as above.
    }
  }
}
