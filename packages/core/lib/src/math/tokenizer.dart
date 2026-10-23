import 'package:core/src/math/math_error.dart';
import 'package:core/src/result.dart';
import 'package:meta/meta.dart';

/// The lexical categories understood by the math grammar.
enum MathTokenType {
  /// A numeric literal, such as `3.14`.
  number,

  /// The addition operator (`+`).
  plus,

  /// The subtraction operator (`-`).
  minus,

  /// The multiplication operator (`*`).
  star,

  /// The division operator (`/`).
  slash,

  /// The modulo operator (`%`).
  percent,

  /// The exponentiation operator (`^`).
  caret,

  /// The factorial postfix operator (`!`).
  bang,

  /// A left parenthesis (`(`).
  leftParenthesis,

  /// A right parenthesis (`)`).
  rightParenthesis,

  /// A named constant, such as `pi`.
  identifier,

  /// The synthetic end-of-input token.
  end,
}

/// A single lexical token with its source position.
@immutable
final class MathToken {
  /// Creates a token.
  const new({
    required this.type,
    required this.lexeme,
    required this.position,
    this.value,
  });

  /// The lexical category.
  final MathTokenType type;

  /// The exact source text of the token.
  final String lexeme;

  /// The zero-based character offset where the token starts.
  final int position;

  /// The numeric value of a [MathTokenType.number] token.
  final double? value;

  @override
  String toString() => '${type.name}($lexeme)';
}

/// Converts expression source text into [MathToken]s.
///
/// The tokenizer is total: malformed input is reported through `Result.err`,
/// never thrown. Whitespace is ignored, and the token list always ends with a
/// [MathTokenType.end] token whose position is the source length.
abstract final class MathTokenizer {
  /// Tokenizes [source].
  static Result<List<MathToken>, MathError> tokenize(String source) {
    final tokens = <MathToken>[];
    var index = 0;

    while (index < source.length) {
      final character = source[index];

      if (_isWhitespace(character)) {
        index++;
        continue;
      }

      if (_isDigit(character) || character == '.') {
        final start = index;
        var hasDigit = false;
        var hasDecimalPoint = false;

        while (index < source.length) {
          final current = source[index];
          if (_isDigit(current)) {
            hasDigit = true;
            index++;
          } else if (current == '.' && !hasDecimalPoint) {
            hasDecimalPoint = true;
            index++;
          } else {
            break;
          }
        }

        final lexeme = source.substring(start, index);
        final value = double.tryParse(lexeme);
        if (!hasDigit || value == null) {
          return Result.err(
            MathError(
              code: MathErrorCode.invalidNumber,
              message: '"$lexeme" is not a valid number.',
              position: start,
            ),
          );
        }

        tokens.add(
          MathToken(
            type: MathTokenType.number,
            lexeme: lexeme,
            position: start,
            value: value,
          ),
        );
        continue;
      }

      if (_isLetter(character)) {
        final start = index;
        while (index < source.length && _isLetter(source[index])) {
          index++;
        }
        tokens.add(
          MathToken(
            type: MathTokenType.identifier,
            lexeme: source.substring(start, index),
            position: start,
          ),
        );
        continue;
      }

      final type = _operatorType(character);
      if (type == null) {
        return Result.err(
          MathError(
            code: MathErrorCode.unexpectedCharacter,
            message: 'Unexpected character "$character".',
            position: index,
          ),
        );
      }

      tokens.add(MathToken(type: type, lexeme: character, position: index));
      index++;
    }

    tokens.add(
      MathToken(type: MathTokenType.end, lexeme: '', position: source.length),
    );
    return Result.ok(tokens);
  }

  static MathTokenType? _operatorType(String character) {
    return switch (character) {
      '+' => MathTokenType.plus,
      '-' => MathTokenType.minus,
      '*' => MathTokenType.star,
      '/' => MathTokenType.slash,
      '%' => MathTokenType.percent,
      '^' => MathTokenType.caret,
      '!' => MathTokenType.bang,
      '(' => MathTokenType.leftParenthesis,
      ')' => MathTokenType.rightParenthesis,
      _ => null,
    };
  }

  static bool _isWhitespace(String character) =>
      character == ' ' ||
      character == '\t' ||
      character == '\n' ||
      character == '\r';

  static bool _isDigit(String character) {
    final code = character.codeUnitAt(0);
    return code >= 0x30 && code <= 0x39;
  }

  static bool _isLetter(String character) {
    final code = character.codeUnitAt(0);
    return (code >= 0x41 && code <= 0x5A) || (code >= 0x61 && code <= 0x7A);
  }
}
