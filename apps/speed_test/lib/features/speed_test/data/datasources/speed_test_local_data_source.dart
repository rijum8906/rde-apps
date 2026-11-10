import 'dart:convert';

import 'package:app_shared/app_shared.dart';
import 'package:speed_test/features/speed_test/domain/entities/speed_test_result.dart';

/// Persists speed test history without exposing storage APIs to the domain.
///
/// Missing, unreadable, or corrupt payloads are treated as an empty history so
/// a bad value can never prevent the app from starting. Individual entries
/// that fail to parse are skipped instead of dropping the whole list.
final class SpeedTestLocalDataSource {
  /// Creates the data source over the supplied store.
  new(this._store);

  /// The key that owns the serialized history.
  static const String storageKey = 'speed_test.history';

  /// The number of results retained on disk.
  static const int maxEntries = maxSpeedTestHistoryEntries;

  final KeyValueStore _store;

  /// Reads the stored results, newest first.
  Future<List<SpeedTestResult>> loadHistory() async {
    final raw = await _store.readString(storageKey);
    if (raw == null) {
      return const [];
    }

    Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      return const [];
    }
    if (decoded is! List) {
      return const [];
    }

    final results = <SpeedTestResult>[];
    for (final item in decoded) {
      if (item is! Map<Object?, Object?>) {
        continue;
      }
      try {
        results.add(SpeedTestResult.fromJson(item));
      } on FormatException {
        continue;
      }
    }
    return results.take(maxEntries).toList(growable: false);
  }

  /// Replaces the stored history with [results].
  Future<void> saveHistory(List<SpeedTestResult> results) => _store.writeString(
    storageKey,
    jsonEncode([for (final result in results) result.toJson()]),
  );

  /// Removes the stored history.
  Future<void> clearHistory() => _store.remove(storageKey);
}
