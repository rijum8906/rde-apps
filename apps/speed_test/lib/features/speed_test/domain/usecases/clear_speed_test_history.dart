import 'package:core/core.dart';
import 'package:speed_test/features/speed_test/domain/failures.dart';
import 'package:speed_test/features/speed_test/domain/repositories/speed_test_repository.dart';

/// Removes every stored speed test.
class ClearSpeedTestHistory {
  /// Creates the use case over [repository].
  const new(this.repository);

  /// The repository that owns stored results.
  final SpeedTestRepository repository;

  /// Clears the history.
  Future<Result<void, SpeedTestFailure>> call() => repository.clearHistory();
}
