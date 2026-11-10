import 'package:meta/meta.dart';

/// A throughput value split into a display number and its unit.
///
/// The domain stores bits per second so no precision is lost; formatting
/// happens only at the edge.
@immutable
final class BandwidthReading {
  /// Creates a reading.
  const new({required this.value, required this.unit});

  /// Converts [bitsPerSecond] into the largest sensible unit.
  // ignore: unnecessary_type_name_in_constructor
  factory BandwidthReading.fromBps(double bitsPerSecond) {
    final safe = bitsPerSecond.isFinite && bitsPerSecond > 0
        ? bitsPerSecond
        : 0.0;
    if (safe >= 1000000000) {
      return BandwidthReading(value: safe / 1000000000, unit: 'Gbps');
    }
    if (safe >= 1000000) {
      return BandwidthReading(value: safe / 1000000, unit: 'Mbps');
    }
    if (safe >= 1000) {
      return BandwidthReading(value: safe / 1000, unit: 'Kbps');
    }
    return BandwidthReading(value: safe, unit: 'bps');
  }

  /// The numeric part of the reading.
  final double value;

  /// The unit that goes with [value].
  final String unit;

  /// The number without its unit, with enough precision to stay informative.
  String get formattedValue {
    if (value >= 100) {
      return value.toStringAsFixed(0);
    }
    if (value >= 10) {
      return value.toStringAsFixed(1);
    }
    return value.toStringAsFixed(1);
  }

  /// The complete reading, for example `94.2 Mbps`.
  String get formatted => '$formattedValue $unit';

  @override
  String toString() => formatted;
}

/// Formats a throughput value with its unit.
String formatBandwidth(double bitsPerSecond) =>
    BandwidthReading.fromBps(bitsPerSecond).formatted;

/// Formats a latency or jitter value in milliseconds.
String formatMilliseconds(double milliseconds) {
  if (!milliseconds.isFinite || milliseconds <= 0) {
    return '—';
  }
  final precision = milliseconds >= 100 ? 0 : 1;
  return '${milliseconds.toStringAsFixed(precision)} ms';
}
