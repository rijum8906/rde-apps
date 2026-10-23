import 'package:meta/meta.dart';

/// One completed calculation.
///
/// Pure Dart: no Flutter, bloc, or storage knowledge.
@immutable
final class Calculation {
  /// Creates a calculation from the exact [expression] and its [result].
  const new({required this.expression, required this.result});

  /// The expression that was evaluated, exactly as typed.
  final String expression;

  /// The evaluated value.
  final double result;

  /// The JSON representation persisted in the key/value store.
  Map<String, Object?> toJson() => <String, Object?>{
    'expression': expression,
    'result': result,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Calculation &&
          other.expression == expression &&
          other.result == result;

  @override
  int get hashCode => Object.hash(expression, result);

  @override
  String toString() => 'Calculation($expression = $result)';
}
