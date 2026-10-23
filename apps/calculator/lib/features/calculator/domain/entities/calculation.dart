/// Core domain entity representing a completed calculation.
/// Pure Dart - NO Flutter imports, NO Bloc, NO storage knowledge.
class Calculation {
  /// Creates a calculation.
  const new({required this.expression, required this.result});

  /// The expression that was evaluated, exactly as typed.
  final String expression;

  /// The evaluated value.
  final double result;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Calculation &&
          other.expression == expression &&
          other.result == result;

  @override
  int get hashCode => expression.hashCode ^ result.hashCode;

  Map<String, Object?> toJson() => <String, Object?>{
    'expression': expression,
    'result': result,
  };
}
