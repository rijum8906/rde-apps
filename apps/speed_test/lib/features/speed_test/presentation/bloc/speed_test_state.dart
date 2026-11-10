import 'package:speed_test/features/speed_test/domain/entities/network_info.dart';
import 'package:speed_test/features/speed_test/domain/entities/speed_test_progress.dart';
import 'package:speed_test/features/speed_test/domain/entities/speed_test_result.dart';

/// Everything the speed test pages render.
final class SpeedTestState {
  /// Creates the state.
  const new({
    this.phase = SpeedTestPhase.idle,
    this.isRunning = false,
    this.progress = 0,
    this.liveBps = 0,
    this.downloadBps,
    this.uploadBps,
    this.latencyMs,
    this.jitterMs,
    this.server,
    this.errorMessage,
    this.history = const [],
    this.result,
  });

  /// The current stage of the run.
  final SpeedTestPhase phase;

  /// Whether a run is in flight.
  final bool isRunning;

  /// Overall progress from 0 to 1.
  final double progress;

  /// The smoothed instantaneous throughput of the active phase.
  final double liveBps;

  /// The measured download throughput, when available.
  final double? downloadBps;

  /// The measured upload throughput, when available.
  final double? uploadBps;

  /// The measured median latency, when available.
  final double? latencyMs;

  /// The measured jitter, when available.
  final double? jitterMs;

  /// The endpoint and network that carried the test.
  final NetworkInfo? server;

  /// The user-facing error, when the last run failed.
  final String? errorMessage;

  /// Persisted results, newest first.
  final List<SpeedTestResult> history;

  /// The result shown on the main page.
  final SpeedTestResult? result;

  /// Whether there is at least one measured result to show.
  bool get hasResult => result != null;

  /// Returns a copy with the given fields replaced.
  SpeedTestState copyWith({
    SpeedTestPhase? phase,
    bool? isRunning,
    double? progress,
    double? liveBps,
    double? downloadBps,
    double? uploadBps,
    double? latencyMs,
    double? jitterMs,
    NetworkInfo? server,
    String? errorMessage,
    List<SpeedTestResult>? history,
    SpeedTestResult? result,
    bool clearError = false,
    bool clearMetrics = false,
  }) {
    return SpeedTestState(
      phase: phase ?? this.phase,
      isRunning: isRunning ?? this.isRunning,
      progress: progress ?? this.progress,
      liveBps: liveBps ?? this.liveBps,
      downloadBps: clearMetrics ? null : downloadBps ?? this.downloadBps,
      uploadBps: clearMetrics ? null : uploadBps ?? this.uploadBps,
      latencyMs: clearMetrics ? null : latencyMs ?? this.latencyMs,
      jitterMs: clearMetrics ? null : jitterMs ?? this.jitterMs,
      server: clearMetrics ? null : server ?? this.server,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      history: history ?? this.history,
      result: clearMetrics ? null : result ?? this.result,
    );
  }
}
