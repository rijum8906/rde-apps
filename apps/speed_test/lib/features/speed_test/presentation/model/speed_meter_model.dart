import 'dart:math' as math;

import 'package:meta/meta.dart';
import 'package:speed_test/features/speed_test/domain/entities/speed_test_progress.dart';
import 'package:speed_test/features/speed_test/presentation/bloc/speed_test_state.dart';
import 'package:speed_test/features/speed_test/presentation/model/bandwidth_reading.dart';

/// Everything the gauge and its readout need for one frame.
@immutable
final class SpeedMeterModel {
  /// Creates a gauge model.
  const new({
    required this.valueBps,
    required this.scaleMaxBps,
    required this.label,
    required this.isRunning,
  });

  /// Derives the gauge state from the bloc state.
  // ignore: unnecessary_type_name_in_constructor
  factory SpeedMeterModel.fromState(SpeedTestState state) {
    final valueBps = switch (state.phase) {
      SpeedTestPhase.download || SpeedTestPhase.upload => state.liveBps,
      SpeedTestPhase.completed => state.downloadBps ?? state.liveBps,
      SpeedTestPhase.idle ||
      SpeedTestPhase.failed => state.result?.downloadBps ?? 0,
      SpeedTestPhase.connecting || SpeedTestPhase.latency => 0.0,
    };
    final peak = math.max(
      valueBps,
      math.max(state.downloadBps ?? 0, state.uploadBps ?? 0),
    );
    return SpeedMeterModel(
      valueBps: valueBps,
      scaleMaxBps: scaleFor(peak),
      label: switch (state.phase) {
        SpeedTestPhase.idle =>
          state.result == null ? 'Ready to test' : 'Last test',
        SpeedTestPhase.connecting => 'Connecting',
        SpeedTestPhase.latency => 'Measuring ping',
        SpeedTestPhase.download => 'Download',
        SpeedTestPhase.upload => 'Upload',
        SpeedTestPhase.completed => 'Download speed',
        SpeedTestPhase.failed => 'Test failed',
      },
      isRunning: state.isRunning,
    );
  }

  /// Picks a readable scale that leaves the needle below the end of the dial.
  static double scaleFor(double peakBps) {
    final mbps = peakBps / 1000000;
    for (final scale in const [100.0, 250.0, 500.0, 1000.0, 2500.0]) {
      if (mbps <= scale * 0.92) {
        return scale * 1000000;
      }
    }
    return mbps * 1.2 * 1000000;
  }

  /// The throughput currently shown on the dial.
  final double valueBps;

  /// The value at the end of the dial.
  final double scaleMaxBps;

  /// A short caption above the readout.
  final String label;

  /// Whether a test is in flight.
  final bool isRunning;

  /// The needle position from 0 to 1.
  double get fraction => (valueBps / scaleMaxBps).clamp(0.0, 1.0);

  /// The formatted readout.
  BandwidthReading get reading => BandwidthReading.fromBps(valueBps);

  /// The formatted top of the scale.
  String get scaleLabel => BandwidthReading.fromBps(scaleMaxBps).formatted;
}
