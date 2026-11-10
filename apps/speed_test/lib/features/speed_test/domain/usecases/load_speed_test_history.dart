import 'package:core/core.dart';
import 'package:speed_test/features/speed_test/domain/entities/speed_test_result.dart';
import 'package:speed_test/features/speed_test/domain/failures.dart';
import 'package:speed_test/features/speed_test/domain/repositories/speed_test_repository.dart';

/// Loads the persisted speed test history.
class LoadSpeedTestHistory {
  /// Creates the use case over [repository].
  const new(this.repository);

  /// The repository that owns stored results.
  final SpeedTestRepository repository;

  /// Returns the stored results, newest first.
  Future<Result<List<SpeedTestResult>, SpeedTestFailure>> call() =>
      repository.loadHistory();
}
