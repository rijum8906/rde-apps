import 'package:core/core.dart';
import 'package:speed_test/features/speed_test/domain/entities/speed_test_config.dart';
import 'package:speed_test/features/speed_test/domain/entities/speed_test_progress.dart';
import 'package:speed_test/features/speed_test/domain/entities/speed_test_result.dart';
import 'package:speed_test/features/speed_test/domain/failures.dart';

/// The domain-facing contract for measuring and remembering speed tests.
///
/// The presentation layer depends only on this interface; the data layer
/// decides which endpoint is used and how results are stored.
abstract interface class SpeedTestRepository {
  /// Runs one test and emits progress until a completed update.
  ///
  /// The stream emits a [SpeedTestFailure] through `addError` when the run
  /// cannot finish, and emits a final [SpeedTestProgress] with
  /// [SpeedTestProgress.phase] `completed` on success.
  Stream<SpeedTestProgress> runTest(SpeedTestConfig config);

  /// Loads past results, newest first.
  Future<Result<List<SpeedTestResult>, SpeedTestFailure>> loadHistory();

  /// Prepends [result] to history and trims the oldest entries.
  Future<Result<void, SpeedTestFailure>> saveResult(SpeedTestResult result);

  /// Removes every stored result.
  Future<Result<void, SpeedTestFailure>> clearHistory();
}
