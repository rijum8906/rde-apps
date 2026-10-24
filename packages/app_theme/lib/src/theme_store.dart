import 'dart:convert';

import 'package:app_shared/app_shared.dart';
import 'package:app_theme/src/app_theme_settings.dart';

/// Persists [AppThemeSettings] in a [KeyValueStore].
///
/// Every app uses the same key, so the local preference keeps the same shape
/// even though each app owns its own store until the theme service exists.
/// Storage failures are swallowed: a theme preference must never block startup.
final class ThemeStore {
  /// Creates a store backed by `store`.
  new(this._store);

  /// The key that owns the persisted theme selection.
  static const String storageKey = 'app.theme';

  final KeyValueStore _store;

  /// Reads the stored selection, or `null` when nothing usable is stored.
  Future<AppThemeSettings?> read() async {
    try {
      final raw = await _store.readString(storageKey);
      if (raw == null) {
        return null;
      }
      return AppThemeSettings.fromJson(jsonDecode(raw));
    } on Object {
      return null;
    }
  }

  /// Persists `settings`, ignoring storage failures.
  Future<void> write(AppThemeSettings settings) async {
    try {
      await _store.writeString(storageKey, jsonEncode(settings.toJson()));
    } on Object {
      // Best-effort: the in-memory selection stays authoritative.
    }
  }

  /// Forgets the stored selection.
  Future<void> clear() async {
    try {
      await _store.remove(storageKey);
    } on Object {
      // Best-effort, as above.
    }
  }
}
