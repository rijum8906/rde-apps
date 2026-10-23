import 'dart:convert';

import 'package:app_shared/app_shared.dart';
import 'package:calculator/features/settings/domain/app_settings.dart';

/// Loads and persists [AppSettings] in the workspace key/value store.
final class SettingsRepository {
  /// Creates a repository backed by `store`.
  new(this._store);

  /// The storage key that owns every calculator preference.
  static const String storageKey = 'calculator.settings';

  final KeyValueStore _store;

  /// Reads the stored preferences, falling back to the defaults.
  ///
  /// Missing, unreadable, or corrupt payloads are never fatal: preferences are
  /// an enhancement, so the calculator always starts.
  Future<AppSettings> load() async {
    try {
      final raw = await _store.readString(storageKey);
      if (raw == null) {
        return AppSettings.defaults;
      }
      return AppSettings.fromJson(jsonDecode(raw));
    } on Object {
      return AppSettings.defaults;
    }
  }

  /// Persists [settings], ignoring storage failures for the same reason.
  Future<void> save(AppSettings settings) async {
    try {
      await _store.writeString(storageKey, jsonEncode(settings.toJson()));
    } on Object {
      // Preferences are best-effort; the in-memory state stays authoritative.
    }
  }

  /// Removes the stored preferences.
  Future<void> reset() async {
    try {
      await _store.remove(storageKey);
    } on Object {
      // Best-effort, as above.
    }
  }
}
