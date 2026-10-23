# core

Pure Dart primitives shared by every app and package in the workspace: a
sealed `Result<T, E>` with exhaustive switching, a zero-dependency `Logger`
abstraction, JSON/async typedefs, string/iterable/`DateTime` extensions, and a
hand-written arithmetic expression engine (tokenizer, recursive-descent parser,
and evaluator). It deliberately has no Flutter dependency so it can be used by
CLI tools, isolates, tests, and the calculator's business logic.

```dart
import 'package:core/core.dart';

final result = MathEvaluator.evaluate('2 + 3 * (4 - 1) / 2');
final label = result.fold(
  onOk: (value) => 'result: $value',
  onErr: (error) => 'invalid: ${error.message}',
);
Logger.noop.info(label);

Result<int, String> parseCount(String raw) {
  final value = int.tryParse(raw);
  return value == null ? const Result.err('not a number') : Result.ok(value);
}
```
