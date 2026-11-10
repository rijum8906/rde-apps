import 'package:speed_test/features/speed_test/domain/entities/speed_test_config.dart';
import 'package:speed_test/features/speed_test/domain/entities/speed_test_progress.dart';
import 'package:speed_test/features/speed_test/domain/repositories/speed_test_repository.dart';

/// Starts a speed test and exposes its progress stream.
class RunSpeedTest {
  /// Creates the use case over [repository].
  const new(this.repository);

  /// The repository that performs the measurements.
  final SpeedTestRepository repository;

  /// Runs a test for [config].
  Stream<SpeedTestProgress> call(SpeedTestConfig config) =>
      repository.runTest(config);
}
