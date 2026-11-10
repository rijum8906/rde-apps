import 'dart:math' as math;
import 'dart:typed_data';

/// How often live throughput is reported.
const int reportIntervalMicros = 100 * 1000;

/// The shortest window used for a throughput sample.
const int sampleWindowMicros = 20 * 1000;

/// Random bytes keep middleboxes from compressing the upload payload.
Uint8List randomPayload(int bytes) {
  final payload = Uint8List(bytes);
  final random = math.Random();
  for (var index = 0; index < payload.length; index++) {
    payload[index] = random.nextInt(256);
  }
  return payload;
}

/// Samples aggregate throughput every window and reports its sustained peak.
///
/// The first quarter of the samples is discarded so TCP slow start does not
/// drag the result down, and the 90th percentile of the rest is reported, which
/// matches how other speed tests present peak throughput.
final class ThroughputSampler {
  final Stopwatch _stopwatch = Stopwatch();
  final List<double> _samples = <double>[];
  int _lastBytes = 0;
  int _lastMicros = 0;
  double _smoothed = 0;

  /// Microseconds since [start] was called.
  int get elapsedMicros => _stopwatch.elapsedMicroseconds;

  /// The latest exponentially smoothed rate, in bits per second.
  double get smoothedBps => _smoothed;

  /// Begins timing the transfer.
  void start() => _stopwatch.start();

  /// Freezes the clock at the end of the transfer.
  void stop() => _stopwatch.stop();

  /// The average rate over the whole transfer, in bits per second.
  double averageBps(int bytes) {
    final seconds = elapsedMicros / 1000000;
    return seconds <= 0 ? 0 : bytes * 8 / seconds;
  }

  /// Records one window, returning the smoothed live rate when it samples.
  double? sample(int bytes, {required bool force}) {
    final micros = elapsedMicros;
    final interval = micros - _lastMicros;
    if (!force && interval < reportIntervalMicros) {
      return null;
    }
    final delta = bytes - _lastBytes;
    if (interval < sampleWindowMicros || delta <= 0) {
      return null;
    }
    final bps = delta * 8 / (interval / 1000000);
    _samples.add(bps);
    _smoothed = _smoothed == 0 ? bps : _smoothed * 0.65 + bps * 0.35;
    _lastBytes = bytes;
    _lastMicros = micros;
    return _smoothed;
  }

  /// The steady-state peak after discarding ramp-up samples.
  double get sustainedBps {
    if (_samples.isEmpty) {
      return 0;
    }
    final start = _samples.length >= 8 ? (_samples.length * 0.25).floor() : 0;
    final steady = _samples.sublist(start);
    if (steady.length < 4) {
      return steady.reduce((a, b) => a + b) / steady.length;
    }
    steady.sort();
    final index = ((steady.length - 1) * 0.9).round();
    return steady[index];
  }
}
