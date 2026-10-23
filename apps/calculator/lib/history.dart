import 'dart:convert';

import 'package:app_shared/app_shared.dart';
import 'package:flutter/foundation.dart';

/// One completed calculation.
@immutable
final class Calculation {
  /// Creates a calculation.
  const new({required this.expression, required this.result});

  /// The expression that was evaluated, exactly as typed.
  final String expression;

  /// The evaluated value.
  final double result;

  Map<String, Object?> _toJson() => <String, Object?>{
    'expression': expression,
    'result': result,
  };
}

/// Loads, appends, and persists up to 20 calculations.
final class CalculatorHistory extends ChangeNotifier {
  /// Creates a history backed by a key/value store.
  new(this._store);

  /// The key used to persist the serialized history.
  static const String storageKey = 'calculator.history';

  /// The maximum number of retained calculations.
  static const int maxEntries = 20;

  final KeyValueStore _store;
  List<Calculation> _entries = const <Calculation>[];

  /// The retained calculations, newest first.
  List<Calculation> get entries => List<Calculation>.unmodifiable(_entries);

  /// Whether no calculation has been recorded.
  bool get isEmpty => _entries.isEmpty;

  /// Reads the persisted history.
  ///
  /// Corrupt or foreign data is ignored rather than thrown, so a bad value can
  /// never prevent the calculator from starting.
  Future<void> load() async {
    final raw = await _store.readString(storageKey);
    if (raw == null) {
      return;
    }

    Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      return;
    }
    if (decoded is! List<Object?>) {
      return;
    }

    final entries = <Calculation>[];
    for (final item in decoded) {
      final calculation = _decodeCalculation(item);
      if (calculation != null) {
        entries.add(calculation);
      }
    }
    _entries = entries.take(maxEntries).toList(growable: false);
    notifyListeners();
  }

  /// Prepends [calculation], trims the list, and persists it.
  Future<void> add(Calculation calculation) async {
    _entries = <Calculation>[
      calculation,
      ..._entries,
    ].take(maxEntries).toList(growable: false);
    notifyListeners();
    await _persist();
  }

  /// Removes every calculation from memory and storage.
  Future<void> clear() async {
    _entries = const <Calculation>[];
    notifyListeners();
    await _store.remove(storageKey);
  }

  Future<void> _persist() {
    final payload = jsonEncode(<Object?>[
      for (final entry in _entries) entry._toJson(),
    ]);
    return _store.writeString(storageKey, payload);
  }
}

Calculation? _decodeCalculation(Object? json) {
  if (json is! Map<Object?, Object?>) {
    return null;
  }
  final expression = json['expression'];
  final result = json['result'];
  if (expression is String && result is num) {
    return Calculation(expression: expression, result: result.toDouble());
  }
  return null;
}
