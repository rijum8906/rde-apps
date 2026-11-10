import 'package:meta/meta.dart';
import 'package:speed_test/features/speed_test/data/datasources/speed_test_remote_data_source.dart';
import 'package:speed_test/features/speed_test/domain/entities/speed_test_config.dart';
import 'package:speed_test/features/speed_test/domain/entities/speed_test_progress.dart';
import 'package:speed_test/features/speed_test/domain/failures.dart';

/// Prefers one measurement network and falls back to another.
///
/// Fast.com's endpoints are public but not part of a versioned API, so a run
/// that cannot start there is retried once on Cloudflare. Once a measurement
/// has begun, a failure is reported instead of silently mixing two networks.
@immutable
final class FallbackSpeedTestDataSource implements SpeedTestRemoteDataSource {
  /// Creates the failover data source from the preferred and backup networks.
  const new(this._primary, this._fallback);

  final SpeedTestRemoteDataSource _primary;
  final SpeedTestRemoteDataSource _fallback;

  @override
  Stream<SpeedTestProgress> runTest(SpeedTestConfig config) async* {
    var measured = false;
    try {
      await for (final progress in _primary.runTest(config)) {
        if (progress.phase == SpeedTestPhase.download ||
            progress.phase == SpeedTestPhase.upload ||
            progress.phase == SpeedTestPhase.completed) {
          measured = true;
        }
        yield progress;
      }
    } on SpeedTestFailure {
      if (measured) {
        rethrow;
      }
      yield* _fallback.runTest(config);
    }
  }
}
