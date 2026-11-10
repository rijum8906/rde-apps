import 'package:meta/meta.dart';
import 'package:speed_test/features/speed_test/domain/entities/network_info.dart';

/// The stage of a speed test.
enum SpeedTestPhase {
  /// Nothing is running.
  idle,

  /// Resolving the endpoint and reading connection metadata.
  connecting,

  /// Measuring round-trip time and jitter.
  latency,

  /// Measuring download throughput.
  download,

  /// Measuring upload throughput.
  upload,

  /// All measurements finished successfully.
  completed,

  /// The run stopped with a failure.
  failed,
}

/// One update emitted while a speed test is running.
///
/// Later updates replace earlier ones; only the completed update carries a
/// full result. Lengths are bits per second, latencies are milliseconds.
@immutable
final class SpeedTestProgress {
  /// Creates a progress update.
  const new({
    required this.phase,
    required this.progress,
    this.liveBps = 0,
    this.downloadBps,
    this.uploadBps,
    this.latencyMs,
    this.jitterMs,
    this.server,
  });

  /// The phase this update belongs to.
  final SpeedTestPhase phase;

  /// Overall progress from 0 to 1.
  final double progress;

  /// The smoothed instantaneous throughput of the active phase.
  final double liveBps;

  /// The average download throughput measured so far.
  final double? downloadBps;

  /// The average upload throughput measured so far.
  final double? uploadBps;

  /// The median round-trip time measured so far.
  final double? latencyMs;

  /// The average variation between latency samples.
  final double? jitterMs;

  /// The endpoint and network that carried the test.
  final NetworkInfo? server;

  /// Whether every measurement has finished.
  bool get isComplete => phase == SpeedTestPhase.completed;

  /// Whether a measurement phase is currently active.
  bool get isActive => switch (phase) {
    SpeedTestPhase.connecting ||
    SpeedTestPhase.latency ||
    SpeedTestPhase.download ||
    SpeedTestPhase.upload => true,
    SpeedTestPhase.idle ||
    SpeedTestPhase.completed ||
    SpeedTestPhase.failed => false,
  };
}
