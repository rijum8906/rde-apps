import 'package:speed_test/features/speed_test/domain/entities/speed_test_config.dart';
import 'package:speed_test/features/speed_test/domain/entities/speed_test_progress.dart';

/// The network side of a speed test.
///
/// Kept separate from storage so the repository can compose the two, and so
/// tests can replace the endpoint without touching persistence.
abstract interface class SpeedTestRemoteDataSource {
  /// Measures [config] and streams progress until the completed update.
  Stream<SpeedTestProgress> runTest(SpeedTestConfig config);
}
