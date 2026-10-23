import 'dart:math' as math;

import 'package:core/core.dart';
import 'package:test/test.dart';

/// Parses [source], failing the test when parsing fails.
Expression _parse(String source) {
  return switch (MathParser.parseSource(source)) {
    Ok(:final value) => value,
    Err(:final error) => fail('Expected "$source" to parse: $error'),
  };
}

/// Parses [source] and returns the expected error.
MathError _error(String source) {
  return switch (MathParser.parseSource(source)) {
    Ok() => fail('Expected "$source" to fail parsing.'),
    Err(:final error) => error,
  };
}

/// Verifies precedence, associativity, and syntax errors.
void main() {
  group('MathParser', () {
    test('multiplication binds tighter than addition', () {
      final expression = _parse('2 + 3 * 4') as BinaryExpression;

      expect(expression.op, BinaryOperator.add);
      expect((expression.left as NumberLiteral).value, 2);
      final right = expression.right as BinaryExpression;
      expect(right.op, BinaryOperator.multiply);
    });

    test('parentheses override precedence', () {
      final expression = _parse('(2 + 3) * 4') as BinaryExpression;

      expect(expression.op, BinaryOperator.multiply);
      expect((expression.left as BinaryExpression).op, BinaryOperator.add);
    });

    test('subtraction and division are left-associative', () {
      final subtraction = _parse('10 - 3 - 2') as BinaryExpression;
      expect(subtraction.op, BinaryOperator.subtract);
      expect(
        (subtraction.left as BinaryExpression).op,
        BinaryOperator.subtract,
      );

      final division = _parse('8 / 4 / 2') as BinaryExpression;
      expect(division.op, BinaryOperator.divide);
      expect((division.left as BinaryExpression).op, BinaryOperator.divide);
    });

    test('exponentiation is right-associative', () {
      final expression = _parse('2 ^ 3 ^ 2') as BinaryExpression;

      expect(expression.op, BinaryOperator.power);
      final right = expression.right as BinaryExpression;
      expect(right.op, BinaryOperator.power);
    });

    test('unary minus binds looser than exponentiation', () {
      final expression = _parse('-2 ^ 2') as UnaryExpression;

      expect(expression.op, UnaryOperator.minus);
      expect((expression.operand as BinaryExpression).op, BinaryOperator.power);
    });

    test('unary minus is allowed in exponents', () {
      final expression = _parse('2 ^ -3') as BinaryExpression;

      expect(expression.op, BinaryOperator.power);
      expect((expression.right as UnaryExpression).op, UnaryOperator.minus);
    });

    test('parses unary plus as a no-op node', () {
      final expression = _parse('+2') as UnaryExpression;

      expect(expression.op, UnaryOperator.plus);
      expect((expression.operand as NumberLiteral).value, 2);
    });

    test('parses constants case-insensitively', () {
      final pi = _parse('PI') as ConstantExpression;
      final e = _parse('e') as ConstantExpression;

      expect(pi.name, 'pi');
      expect(pi.value, math.pi);
      expect(e.name, 'e');
      expect(e.value, math.e);
    });

    test('parses modulo', () {
      expect((_parse('7 % 3') as BinaryExpression).op, BinaryOperator.modulo);
    });

    test('reports an empty expression', () {
      expect(_error('').code, MathErrorCode.emptyExpression);
      expect(_error('   ').code, MathErrorCode.emptyExpression);
    });

    test('reports trailing tokens', () {
      final error = _error('1 2');

      expect(error.code, MathErrorCode.unexpectedToken);
      expect(error.position, 2);
    });

    test('reports a missing closing parenthesis', () {
      final error = _error('(1 + 2');

      expect(error.code, MathErrorCode.unexpectedEnd);
      expect(error.message, contains('parenthesis'));
    });

    test('reports an unexpected closing parenthesis', () {
      expect(_error('1)').code, MathErrorCode.unexpectedToken);
    });

    test('reports incomplete expressions', () {
      expect(_error('1 +').code, MathErrorCode.unexpectedEnd);
      expect(_error('* 2').code, MathErrorCode.unexpectedToken);
    });

    test('reports every unexpected leading operator', () {
      for (final source in ['/ 2', '% 2', '^ 2', ') 2']) {
        expect(
          _error(source).code,
          MathErrorCode.unexpectedToken,
          reason: source,
        );
      }
    });

    test('reports unknown identifiers', () {
      final error = _error('sin(1)');

      expect(error.code, MathErrorCode.unknownIdentifier);
      expect(error.position, 0);
    });

    test('propagates tokenizer failures', () {
      expect(_error('1 & 2').code, MathErrorCode.unexpectedCharacter);
    });
  });
}
