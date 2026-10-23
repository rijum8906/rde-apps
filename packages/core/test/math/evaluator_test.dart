import 'dart:math' as math;

import 'package:core/core.dart';
import 'package:test/test.dart';

/// Evaluates [source], failing the test when evaluation fails.
double _eval(String source) {
  return switch (MathEvaluator.evaluate(source)) {
    Ok(:final value) => value,
    Err(:final error) => fail('Expected "$source" to evaluate: $error'),
  };
}

/// Evaluates [source] and returns the expected error.
MathError _error(String source) {
  return switch (MathEvaluator.evaluate(source)) {
    Ok(:final value) => fail('Expected "$source" to fail, got $value.'),
    Err(:final error) => error,
  };
}

/// Verifies arithmetic semantics and failure modes.
void main() {
  group('MathEvaluator', () {
    test('evaluates the motivating expression', () {
      expect(_eval('2 + 3 * (4 - 1) / 2'), closeTo(6.5, 1e-12));
    });

    test('honors precedence and parentheses', () {
      expect(_eval('2 + 3 * 4'), 14);
      expect(_eval('(2 + 3) * 4'), 20);
      expect(_eval('10 - 3 - 2'), 5);
      expect(_eval('8 / 4 / 2'), 1);
    });

    test('evaluates decimals and leading dots', () {
      expect(_eval('0.1 + 0.2'), closeTo(0.3, 1e-12));
      expect(_eval('.5 * 2'), 1);
      expect(_eval('1.5 + 2.25'), 3.75);
    });

    test('evaluates exponentiation with right associativity', () {
      expect(_eval('2 ^ 3 ^ 2'), 512);
      expect(_eval('2 ^ -2'), 0.25);
      expect(_eval('0 ^ 0'), 1);
    });

    test('applies unary minus with the right precedence', () {
      expect(_eval('-2 ^ 2'), -4);
      expect(_eval('(-2) ^ 2'), 4);
      expect(_eval('-5 + 2'), -3);
      expect(_eval('--3'), 3);
      expect(_eval('-(2 + 3)'), -5);
    });

    test('evaluates modulo', () {
      expect(_eval('10 % 4'), 2);
      expect(_eval('10 % 4 * 2'), 4);
    });

    test('evaluates constants', () {
      expect(_eval('pi'), closeTo(math.pi, 1e-12));
      expect(_eval('e'), closeTo(math.e, 1e-12));
      expect(_eval('2 * pi'), closeTo(2 * math.pi, 1e-12));
      expect(_eval('E'), closeTo(math.e, 1e-12));
      expect(_eval('2pi'), closeTo(2 * math.pi, 1e-12));
      expect(_eval('2sin(30)'), closeTo(1, 1e-12));
    });

    test('evaluates scientific functions in degree and radian modes', () {
      expect(_eval('sin(30)'), closeTo(.5, 1e-12));
      expect(
        MathEvaluator.evaluate('sin(30)', angleMode: AngleMode.radians),
        isA<Ok<double, MathError>>().having(
          (result) => result.value,
          'value',
          closeTo(math.sin(30), 1e-12),
        ),
      );
      expect(_eval('cos(60)'), closeTo(.5, 1e-12));
      expect(_eval('tan(45)'), closeTo(1, 1e-12));
      expect(_eval('asin(.5)'), closeTo(30, 1e-12));
      expect(_eval('acos(.5)'), closeTo(60, 1e-12));
      expect(_eval('atan(1)'), closeTo(45, 1e-12));
      expect(_eval('ln(e)'), closeTo(1, 1e-12));
      expect(_eval('log(100)'), closeTo(2, 1e-12));
      expect(_eval('sqrt(9)'), 3);
      expect(_eval('5!'), 120);
      expect(_eval('50%'), .5);
    });

    test('returns an error for division by zero', () {
      final error = _error('1 / 0');

      expect(error.code, MathErrorCode.divisionByZero);
      expect(error.message, contains('divide by zero'));
    });

    test('returns an error for modulo by zero', () {
      final error = _error('5 % 0');

      expect(error.code, MathErrorCode.divisionByZero);
      expect(error.message, contains('zero divisor'));
    });

    test('returns an error for non-finite results', () {
      expect(_error('2 ^ 2000').code, MathErrorCode.undefinedResult);
      expect(_error('(-1) ^ 0.5').code, MathErrorCode.undefinedResult);
    });

    test('returns typed domain errors', () {
      expect(_error('sqrt(-1)').code, MathErrorCode.domainError);
      expect(_error('ln(0)').code, MathErrorCode.domainError);
      expect(_error('log(-1)').code, MathErrorCode.domainError);
      expect(_error('asin(2)').code, MathErrorCode.domainError);
      expect(_error('(-1)!').code, MathErrorCode.invalidFactorial);
      expect(_error('1.5!').code, MathErrorCode.invalidFactorial);
    });

    test('propagates syntax errors instead of throwing', () {
      expect(_error('1 +').code, MathErrorCode.unexpectedEnd);
      expect(_error('').code, MathErrorCode.emptyExpression);
      expect(_error('(1 + 2').code, MathErrorCode.unexpectedEnd);
      expect(_error('foo').code, MathErrorCode.unknownIdentifier);
      expect(_error('1 & 2').code, MathErrorCode.unexpectedCharacter);
    });
  });
}
