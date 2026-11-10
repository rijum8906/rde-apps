import 'package:meta/meta.dart';
import 'package:speed_test/features/speed_test/domain/entities/speed_test_profile.dart';

/// Everything one test run needs to know.
@immutable
final class SpeedTestConfig {
  /// Creates a configuration for [profile].
  const new({
    this.profile = SpeedTestProfile.balanced,
    this.timeout = const Duration(seconds: 30),
  });

  /// The data volume and sample count used by the run.
  final SpeedTestProfile profile;

  /// The longest a single request may go without progress.
  final Duration timeout;

  /// The number of bytes downloaded during the test.
  int get downloadBytes => profile.downloadBytes;

  /// The number of bytes uploaded during the test.
  int get uploadBytes => profile.uploadBytes;

  /// The number of latency samples taken after the warm-up round trip.
  int get latencySamples => profile.latencySamples;

  /// The number of parallel streams used by download and upload.
  int get connections => profile.connections;
}
