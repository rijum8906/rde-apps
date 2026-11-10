import 'package:flutter_test/flutter_test.dart';
import 'package:speed_test/features/speed_test/data/datasources/fallback_speed_test_data_source.dart';
import 'package:speed_test/features/speed_test/data/datasources/speed_test_remote_data_source.dart';
import 'package:speed_test/features/speed_test/domain/entities/speed_test_config.dart';
import 'package:speed_test/features/speed_test/domain/entities/speed_test_progress.dart';
import 'package:speed_test/features/speed_test/domain/failures.dart';

final class _ScriptedSource implements SpeedTestRemoteDataSource {
  new(this._script);

  final Stream<SpeedTestProgress> Function() _script;
  int calls = 0;

  @override
  Stream<SpeedTestProgress> runTest(SpeedTestConfig config) {
    calls++;
    return _script();
  }
}

void main() {
  const config = SpeedTestConfig();

  test('falls back when the preferred network cannot start', () async {
    final primary = _ScriptedSource(() async* {
      yield const SpeedTestProgress(
        phase: SpeedTestPhase.connecting,
        progress: 0.01,
      );
      throw const ServerFailure();
    });
    final fallback = _ScriptedSource(() async* {
      yield const SpeedTestProgress(
        phase: SpeedTestPhase.completed,
        progress: 1,
      );
    });
    final source = FallbackSpeedTestDataSource(primary, fallback);

    final phases = await source
        .runTest(config)
        .map((progress) => progress.phase)
        .toList();

    expect(phases, [SpeedTestPhase.connecting, SpeedTestPhase.completed]);
    expect(fallback.calls, 1);
  });

  test('reports a failure after a measurement has started', () async {
    final primary = _ScriptedSource(() async* {
      yield const SpeedTestProgress(
        phase: SpeedTestPhase.download,
        progress: 0.3,
      );
      throw const ServerFailure();
    });
    final fallback = _ScriptedSource(() async* {
      yield const SpeedTestProgress(
        phase: SpeedTestPhase.completed,
        progress: 1,
      );
    });
    final source = FallbackSpeedTestDataSource(primary, fallback);

    await expectLater(
      source.runTest(config),
      emitsInOrder(<Object>[
        isA<SpeedTestProgress>().having(
          (progress) => progress.phase,
          'phase',
          SpeedTestPhase.download,
        ),
        emitsError(isA<ServerFailure>()),
      ]),
    );
    expect(fallback.calls, 0);
  });
}
