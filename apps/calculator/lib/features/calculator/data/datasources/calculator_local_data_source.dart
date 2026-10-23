import 'dart:convert';

import 'package:app_shared/app_shared.dart';
import 'package:calculator/features/calculator/domain/entities/calculation.dart';

/// Persists calculator history without exposing storage APIs to the domain.
class CalculatorLocalDataSource {
  new(this._store);

  static const storageKey = 'calculator.history';
  static const maxEntries = 20;
  final KeyValueStore _store;

  Future<List<Calculation>> loadHistory() async {
    final raw = await _store.readString(storageKey);
    if (raw == null) return const [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
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

  Future<void> saveHistory(List<Calculation> calculations) =>
      _store.writeString(
        storageKey,
        jsonEncode([
          for (final item in calculations)
            {'expression': item.expression, 'result': item.result},
        ]),
      );

  Future<void> clearHistory() => _store.remove(storageKey);
}
