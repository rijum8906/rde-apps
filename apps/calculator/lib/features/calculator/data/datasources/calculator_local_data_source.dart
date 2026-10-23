import 'dart:convert';

import 'package:app_shared/app_shared.dart';
import 'package:calculator/features/calculator/domain/entities/calculation.dart';

/// Persists calculator history without exposing storage APIs to the domain.
///
/// Missing, unreadable, or corrupt payloads are treated as an empty history
/// rather than thrown, so a bad value can never prevent the app from starting.
class CalculatorLocalDataSource {
  /// Creates the data source over `store`.
  new(this._store);

  /// The key that owns the serialized history.
  static const String storageKey = 'calculator.history';

  /// The number of calculations retained on disk.
  static const int maxEntries = 20;

  final KeyValueStore _store;

  /// Reads the stored calculations, newest first.
  Future<List<Calculation>> loadHistory() async {
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

    final calculations = <Calculation>[];
    for (final item in decoded) {
      if (item is! Map<Object?, Object?> ||
          item['expression'] is! String ||
          item['result'] is! num) {
        continue;
      }
      calculations.add(
        Calculation(
          expression: item['expression']! as String,
          result: (item['result']! as num).toDouble(),
        ),
      );
    }
    return calculations.take(maxEntries).toList(growable: false);
  }

  /// Replaces the stored history with [calculations].
  Future<void> saveHistory(List<Calculation> calculations) =>
      _store.writeString(
        storageKey,
        jsonEncode([for (final item in calculations) item.toJson()]),
      );

  /// Removes the stored history.
  Future<void> clearHistory() => _store.remove(storageKey);
}
