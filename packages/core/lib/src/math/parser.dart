import 'dart:math' as math;

import 'package:core/src/math/math_error.dart';
import 'package:core/src/math/tokenizer.dart';
import 'package:core/src/result.dart';

/// A node in a parsed arithmetic expression.
sealed class Expression {
  /// Creates an expression node.
  const new();
}

/// A literal number such as `3.5`.
final class NumberLiteral extends Expression {
  /// Creates a number literal.
  const new(this.value);

  /// The literal value.
  final double value;
}

/// A named constant such as `pi` or `e`.
final class ConstantExpression extends Expression {
  /// Creates a constant reference.
  const new({required this.name, required this.value});

  /// The constant's source name.
  final String name;

  /// The constant's value.
  final double value;
}

/// A named unary function, such as `sin(30)`.
final class FunctionExpression extends Expression {
  /// Creates a function expression.
  const new({required this.name, required this.argument});

  /// The normalized function name.
  final String name;

  /// The function argument.
  final Expression argument;
}

/// A postfix operation such as factorial or percentage.
final class PostfixExpression extends Expression {
  /// Creates a postfix expression.
  const new({required this.op, required this.operand});

  /// The postfix operator token.
  final PostfixOperator op;

  /// The operation operand.
  final Expression operand;
}

/// The supported postfix operators.
enum PostfixOperator { factorial, percent }

/// The unary operators supported by the grammar.
enum UnaryOperator {
  /// Unary plus, which leaves the operand unchanged.
  plus,

  /// Unary minus, which negates the operand.
  minus,
}

/// An expression with a single operand, such as `-3`.
final class UnaryExpression extends Expression {
  /// Creates a unary expression.
  const new({required this.op, required this.operand});

  /// The applied operator.
  final UnaryOperator op;

  /// The operand.
  final Expression operand;
}

/// The binary operators supported by the grammar.
enum BinaryOperator {
  /// Addition (`+`).
  add,

  /// Subtraction (`-`).
  subtract,

  /// Multiplication (`*`).
  multiply,

  /// Division (`/`).
  divide,

  /// Remainder (`%`).
  modulo,

  /// Exponentiation (`^`).
  power,
}

/// An expression with two operands, such as `2 + 3`.
final class BinaryExpression extends Expression {
  /// Creates a binary expression.
  const new({required this.op, required this.left, required this.right});

  /// The applied operator.
  final BinaryOperator op;

  /// The left operand.
  final Expression left;

  /// The right operand.
  final Expression right;
}

/// A recursive-descent parser for arithmetic expressions.
///
/// Grammar (lowest to highest precedence):
///
/// ```text
/// expression := term (('+' | '-') term)*
/// term       := unary (('*' | '/' | '%') unary | implicit-multiply unary)*
/// unary      := ('+' | '-') unary | power
/// power      := primary ('^' unary)?      // right-associative
/// primary    := number | constant | function '(' expression ')' | '(' expression ')'
/// ```
///
/// Exponentiation is right-associative and binds tighter than unary minus, so
/// `-2^2` is `-(2^2)` and `2^3^2` is `2^(3^2)`.
final class MathParser {
  /// Creates a parser over `tokens`, which must end with an end token.
  new(this._tokens);

  final List<MathToken> _tokens;
  var _index = 0;

  /// Tokenizes and parses [source] in one step.
  static Result<Expression, MathError> parseSource(String source) {
    return MathTokenizer.tokenize(source)
        .flatMap((tokens) => MathParser(tokens).parse());
  }

  /// Parses the token stream into an [Expression].
  Result<Expression, MathError> parse() {
    if (_current.type == MathTokenType.end) {
      return const Result.err(
        MathError(
          code: MathErrorCode.emptyExpression,
          message: 'Enter an expression.',
          position: 0,
        ),
      );
    }

    try {
      final expression = _expression();
      final trailing = _current;
      if (trailing.type != MathTokenType.end) {
        throw _fail(
          MathErrorCode.unexpectedToken,
          'Unexpected "${trailing.lexeme}" after the expression.',
          trailing.position,
        );
      }
      return Result.ok(expression);
    } on _ParseFailure catch (failure) {
      return Result.err(failure.error);
    }
  }

  MathToken get _current => _tokens[_index];

  MathToken _advance() {
    final token = _current;
    if (token.type != MathTokenType.end) {
      _index++;
    }
    return token;
  }

  bool _match(MathTokenType type) {
    if (_current.type != type) {
      return false;
    }
    _advance();
    return true;
  }

  Expression _expression() {
    var expression = _term();
    while (true) {
      if (_match(MathTokenType.plus)) {
        expression = BinaryExpression(
          op: BinaryOperator.add,
          left: expression,
          right: _term(),
        );
      } else if (_match(MathTokenType.minus)) {
        expression = BinaryExpression(
          op: BinaryOperator.subtract,
          left: expression,
          right: _term(),
        );
      } else {
        return expression;
      }
    }
  }

  Expression _term() {
    var expression = _unary();
    while (true) {
      if (_match(MathTokenType.star)) {
        expression = BinaryExpression(
          op: BinaryOperator.multiply,
          left: expression,
          right: _unary(),
        );
      } else if (_match(MathTokenType.slash)) {
        expression = BinaryExpression(
          op: BinaryOperator.divide,
          left: expression,
          right: _unary(),
        );
      } else if (_match(MathTokenType.percent)) {
        if (_startsPrimary(_current)) {
          expression = BinaryExpression(
            op: BinaryOperator.modulo,
            left: expression,
            right: _unary(),
          );
        } else {
          expression = PostfixExpression(
            op: PostfixOperator.percent,
            operand: expression,
          );
        }
      } else if (_startsPrimary(_current)) {
        expression = BinaryExpression(
          op: BinaryOperator.multiply,
          left: expression,
          right: _unary(),
        );
      } else {
        return expression;
      }
    }
  }

  Expression _unary() {
    if (_match(MathTokenType.plus)) {
      return UnaryExpression(op: UnaryOperator.plus, operand: _unary());
    }
    if (_match(MathTokenType.minus)) {
      return UnaryExpression(op: UnaryOperator.minus, operand: _unary());
    }
    return _power();
  }

  Expression _power() {
    var base = _primary();
    while (true) {
      if (_match(MathTokenType.bang)) {
        base = PostfixExpression(op: PostfixOperator.factorial, operand: base);
      } else if (_current.type == MathTokenType.percent &&
          !_startsPrimary(
            _tokens[_index + 1 < _tokens.length ? _index + 1 : _index],
          )) {
        _advance();
        base = PostfixExpression(op: PostfixOperator.percent, operand: base);
      } else {
        break;
      }
    }
    if (_match(MathTokenType.caret)) {
      return BinaryExpression(
        op: BinaryOperator.power,
        left: base,
        right: _unary(),
      );
    }
    return base;
  }

  Expression _primary() {
    final token = _current;
    switch (token.type) {
      case MathTokenType.number:
        _advance();
        return NumberLiteral(token.value!);
      case MathTokenType.identifier:
        _advance();
        final name = token.lexeme.toLowerCase();
        if (_functions.contains(name)) {
          if (!_match(MathTokenType.leftParenthesis)) {
            throw _fail(
              MathErrorCode.unexpectedToken,
              'Function "$name" needs an argument in parentheses.',
              _current.position,
            );
          }
          final argument = _expression();
          if (!_match(MathTokenType.rightParenthesis)) {
            throw _fail(
              MathErrorCode.unexpectedEnd,
              'Missing closing parenthesis.',
              _current.position,
            );
          }
          return FunctionExpression(name: name, argument: argument);
        }
        return switch (name) {
          'pi' => const ConstantExpression(name: 'pi', value: math.pi),
          'e' => const ConstantExpression(name: 'e', value: math.e),
          _ => throw _fail(
            MathErrorCode.unknownIdentifier,
            'Unknown constant "${token.lexeme}".',
            token.position,
          ),
        };
      case MathTokenType.leftParenthesis:
        _advance();
        final expression = _expression();
        if (_current.type != MathTokenType.rightParenthesis) {
          throw _fail(
            _current.type == MathTokenType.end
                ? MathErrorCode.unexpectedEnd
                : MathErrorCode.unexpectedToken,
            'Missing closing parenthesis.',
            _current.position,
          );
        }
        _advance();
        return expression;
      case MathTokenType.end:
        throw _fail(
          MathErrorCode.unexpectedEnd,
          'Unexpected end of expression.',
          token.position,
        );
      case MathTokenType.plus ||
          MathTokenType.minus ||
          MathTokenType.star ||
          MathTokenType.slash ||
          MathTokenType.percent ||
          MathTokenType.caret ||
          MathTokenType.bang ||
          MathTokenType.rightParenthesis:
        throw _fail(
          MathErrorCode.unexpectedToken,
          'Unexpected "${token.lexeme}".',
          token.position,
        );
    }
  }

  _ParseFailure _fail(MathErrorCode code, String message, int position) {
    return _ParseFailure(
      MathError(code: code, message: message, position: position),
    );
  }

  static const Set<String> _functions = {
    'sin', 'cos', 'tan', 'asin', 'acos', 'atan', 'ln', 'log', 'sqrt',
  };

  bool _startsPrimary(MathToken token) =>
      token.type == MathTokenType.number ||
      token.type == MathTokenType.identifier ||
      token.type == MathTokenType.leftParenthesis;
}

final class _ParseFailure implements Exception {
  const new(this.error);

  final MathError error;
}
