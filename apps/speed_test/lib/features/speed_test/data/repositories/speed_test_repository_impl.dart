import 'package:core/core.dart';
import 'package:speed_test/features/speed_test/data/datasources/speed_test_local_data_source.dart';
import 'package:speed_test/features/speed_test/data/datasources/speed_test_remote_data_source.dart';
import 'package:speed_test/features/speed_test/domain/entities/speed_test_config.dart';
import 'package:speed_test/features/speed_test/domain/entities/speed_test_progress.dart';
import 'package:speed_test/features/speed_test/domain/entities/speed_test_result.dart';
import 'package:speed_test/features/speed_test/domain/failures.dart';
import 'package:speed_test/features/speed_test/domain/repositories/speed_test_repository.dart';

/// Joins the remote measurements with local history storage.
final class SpeedTestRepositoryImpl implements SpeedTestRepository {
  /// Creates the repository from its data sources.
  new({required this._remote, required this._local});

  final SpeedTestRemoteDataSource _remote;
  final SpeedTestLocalDataSource _local;

  @override
  Stream<SpeedTestProgress> runTest(SpeedTestConfig config) =>
      _remote.runTest(config);

  @override
  Future<Result<List<SpeedTestResult>, SpeedTestFailure>> loadHistory() async {
    try {
      return Result.ok(await _local.loadHistory());
    } on Object {
      return const Result.err(StorageFailure());
    }
  }

  @override
  Future<Result<void, SpeedTestFailure>> saveResult(
    SpeedTestResult result,
  ) async {
    try {
      final current = await _local.loadHistory();
      await _local.saveHistory(
        [
          result,
          ...current,
        ].take(SpeedTestLocalDataSource.maxEntries).toList(growable: false),
      );
      return const Result.ok(null);
    } on Object {
      return const Result.err(StorageFailure());
    }
  }

  @override
  Future<Result<void, SpeedTestFailure>> clearHistory() async {
    try {
      await _local.clearHistory();
      return const Result.ok(null);
    } on Object {
      return const Result.err(StorageFailure());
    }
  }
}
