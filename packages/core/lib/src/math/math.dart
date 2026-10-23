/// A dependency-free arithmetic expression engine.
///
/// Use `MathEvaluator.evaluate` for the one-shot API, or compose
/// `MathTokenizer` and `MathParser` when the syntax tree is needed.
library;

export 'evaluator.dart';
export 'math_error.dart';
export 'parser.dart';
export 'tokenizer.dart';
