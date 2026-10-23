import 'package:core/core.dart';
import 'package:test/test.dart';

/// Verifies the sealed [Result] API and its exhaustive switch support.
void main() {
  group('Result', () {
    test('Ok exposes its value and reports success', () {
      const result = Result<int, String>.ok(7);

      expect(result.isOk, isTrue);
      expect(result.isErr, isFalse);
      expect(result.valueOrNull, 7);
      expect(result.errorOrNull, isNull);
    });

    test('Err exposes its error and optional stack trace', () {
      final stackTrace = StackTrace.current;
      final result = Result<int, String>.err('boom', stackTrace: stackTrace);

      expect(result.isErr, isTrue);
      expect(result.valueOrNull, isNull);
      expect(result.errorOrNull, 'boom');
      expect((result as Err<int, String>).stackTrace, same(stackTrace));
    });

    test('fold and switch are exhaustive over both branches', () {
      const ok = Result<int, String>.ok(2);
      const err = Result<int, String>.err('nope');

      String describe(Result<int, String> result) => switch (result) {
        Ok(:final value) => 'value=$value',
        Err(:final error) => 'error=$error',
      };

      expect(describe(ok), 'value=2');
      expect(describe(err), 'error=nope');
      expect(ok.fold(onOk: (value) => value * 2, onErr: (error) => -1), 4);
      expect(
        err.fold(onOk: (value) => value * 2, onErr: (error) => error.length),
        4,
      );
    });

    test('map and flatMap only transform success values', () {
      const ok = Result<int, String>.ok(3);
      const err = Result<int, String>.err('bad');

      expect(ok.map((value) => value + 1).valueOrNull, 4);
      expect(err.map((value) => value + 1).errorOrNull, 'bad');
      expect(
        ok.flatMap((value) => Result<String, String>.ok('$value')).valueOrNull,
        '3',
      );
      expect(err.flatMap(Result<int, String>.ok).isErr, isTrue);
    });

    test('mapError and getOrElseCompute recover from failures', () {
      const err = Result<int, int>.err(404);

      expect(
        err.mapError((error) => 'status $error').errorOrNull,
        'status 404',
      );
      expect(err.getOrElse(0), 0);
      expect(err.getOrElseCompute((error) => error * 2), 808);
      expect(const Result<int, int>.ok(5).getOrElseCompute((e) => e), 5);
    });

    test('value equality is structural', () {
      expect(const Result<int, String>.ok(1), const Result<int, String>.ok(1));
      expect(
        const Result<int, String>.ok(1),
        isNot(const Result<int, String>.ok(2)),
      );
    });
  });

  group('Logger', () {
    test('CallbackLogger forwards every record to its sink', () {
      final records = <LogRecord>[];
      final logger = CallbackLogger(records.add)
        ..info('started')
        ..error('failed', error: StateError('bad'));

      expect(logger, isA<CallbackLogger>());
      expect(records, hasLength(2));
      expect(records.first.level, LogLevel.info);
      expect(records.last.error, isA<StateError>());
      expect(records.last.toString(), contains('failed'));
    });

    test('memory logger records entries', () {
      final records = <LogRecord>[];
      Logger.memory(records).warning('careful');

      expect(records.single.level, LogLevel.warning);
    });

    test('noop logger discards entries', () {
      expect(() => Logger.noop.debug('ignored'), returnsNormally);
    });
  });
}
