import 'package:speed_test/features/speed_test/domain/entities/speed_test_config.dart';
import 'package:speed_test/features/speed_test/domain/entities/speed_test_progress.dart';

/// Everything the speed test bloc reacts to.
sealed class SpeedTestEvent {
  /// Creates an event.
  const new();
}

/// Loads persisted history and shows the most recent result.
class SpeedTestStarted extends SpeedTestEvent {
  /// Creates the event.
  const new();
}

/// Starts a run with the given [config].
class StartSpeedTest extends SpeedTestEvent {
  /// Creates the event.
  const new(this.config);

  /// The profile and timeout used by the run.
  final SpeedTestConfig config;
}

/// Stops the active run and returns to the last saved result.
class CancelSpeedTest extends SpeedTestEvent {
  /// Creates the event.
  const new();
}

/// Removes every stored result.
class ClearSpeedTestHistory extends SpeedTestEvent {
  /// Creates the event.
  const new();
}

/// Internal: one update from the measurement stream.
class SpeedTestProgressReceived extends SpeedTestEvent {
  /// Creates the event.
  const new(this.progress);

  /// The update emitted by the repository.
  final SpeedTestProgress progress;
}

/// Internal: the measurement stream failed.
class SpeedTestRunFailed extends SpeedTestEvent {
  /// Creates the event.
  const new(this.error);

  /// The failure thrown by the repository.
  final Object error;
}

/// Internal: the measurement stream closed.
class SpeedTestRunClosed extends SpeedTestEvent {
  /// Creates the event.
  const new();
}
