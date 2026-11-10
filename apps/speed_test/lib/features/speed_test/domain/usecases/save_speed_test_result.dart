import 'package:core/core.dart';
import 'package:speed_test/features/speed_test/domain/entities/speed_test_result.dart';
import 'package:speed_test/features/speed_test/domain/failures.dart';
import 'package:speed_test/features/speed_test/domain/repositories/speed_test_repository.dart';

/// Persists one finished test.
class SaveSpeedTestResult {
  /// Creates the use case over [repository].
  const new(this.repository);

  /// The repository that owns stored results.
  final SpeedTestRepository repository;

  /// Stores [result] at the top of the history.
  Future<Result<void, SpeedTestFailure>> call(SpeedTestResult result) =>
      repository.saveResult(result);
}
