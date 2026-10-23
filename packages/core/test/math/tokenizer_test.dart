import 'package:core/core.dart';
import 'package:test/test.dart';

/// Tokenizes [source], failing the test when tokenization fails.
List<MathToken> _tokens(String source) {
  return switch (MathTokenizer.tokenize(source)) {
    Ok(:final value) => value,
    Err(:final error) => fail('Expected "$source" to tokenize: $error'),
  };
}

/// Tokenizes [source] and returns the expected error.
MathError _error(String source) {
  return switch (MathTokenizer.tokenize(source)) {
    Ok() => fail('Expected "$source" to fail tokenization.'),
    Err(:final error) => error,
  };
}

/// Verifies the lexical grammar of the expression engine.
void main() {
  group('MathTokenizer', () {
    test('tokenizes every operator, number, and parenthesis', () {
      final tokens = _tokens('1 + 2.5 * (pi - e) / 3 % 4 ^ 2');

      expect(tokens.map((token) => token.type).toList(), [
        MathTokenType.number,
        MathTokenType.plus,
        MathTokenType.number,
        MathTokenType.star,
        MathTokenType.leftParenthesis,
        MathTokenType.identifier,
        MathTokenType.minus,
        MathTokenType.identifier,
        MathTokenType.rightParenthesis,
        MathTokenType.slash,
        MathTokenType.number,
        MathTokenType.percent,
        MathTokenType.number,
        MathTokenType.caret,
        MathTokenType.number,
        MathTokenType.end,
      ]);
      expect(tokens[0].value, 1);
      expect(tokens[2].value, 2.5);
      expect(tokens[5].lexeme, 'pi');
      expect(tokens[7].lexeme, 'e');
      expect(tokens.last.lexeme, isEmpty);
    });

    test('records zero-based positions and the end offset', () {
      final tokens = _tokens('10+2');

      expect(tokens[0].position, 0);
      expect(tokens[1].position, 2);
      expect(tokens[2].position, 3);
      expect(tokens.last.position, 4);
    });

    test('accepts leading, trailing, and bare decimal points', () {
      expect(_tokens('.5').first.value, 0.5);
      expect(_tokens('2.').first.value, 2);
      expect(_tokens('3.14').first.value, 3.14);
    });

    test('skips whitespace between tokens', () {
      final tokens = _tokens('  1\t+\n2 ');

      expect(tokens.map((token) => token.type).toList(), [
        MathTokenType.number,
        MathTokenType.plus,
        MathTokenType.number,
        MathTokenType.end,
      ]);
    });

    test('keeps identifier case for the parser to normalize', () {
      expect(_tokens('PI').first.lexeme, 'PI');
      expect(_tokens('PI').first.type, MathTokenType.identifier);
    });

    test('returns an empty expression as a single end token', () {
      expect(_tokens('').single.type, MathTokenType.end);
      expect(_tokens('   ').single.position, 3);
    });

    test('rejects characters outside the grammar', () {
      final error = _error('1 & 2');

      expect(error.code, MathErrorCode.unexpectedCharacter);
      expect(error.position, 2);
      expect(error.toString(), contains('Unexpected character'));
    });

    test('rejects a lone decimal point', () {
      final error = _error('.');

      expect(error.code, MathErrorCode.invalidNumber);
      expect(error.position, 0);
    });

    test('rejects a second decimal point in a literal', () {
      final tokens = _tokens('1.2.3');

      // The tokenizer produces two numbers; the parser rejects the trailing
      // token. The tokenizer itself stays total and does not throw.
      expect(tokens.length, 3);
      expect(tokens.first.value, 1.2);
      expect(tokens[1].value, 0.3);
    });

    test('exposes readable token strings', () {
      expect(_tokens('42').first.toString(), 'number(42)');
    });
  });
}
