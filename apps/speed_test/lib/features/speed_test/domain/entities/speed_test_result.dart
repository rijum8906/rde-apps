import 'package:meta/meta.dart';
import 'package:speed_test/features/speed_test/domain/entities/network_info.dart';
import 'package:speed_test/features/speed_test/domain/entities/speed_test_profile.dart';
import 'package:speed_test/features/speed_test/domain/entities/speed_test_progress.dart';

/// The number of results kept in the local history.
const int maxSpeedTestHistoryEntries = 20;

/// One finished speed test.
///
/// This is the shape stored on disk and shown in history. It is pure Dart: no
/// Flutter, bloc, or storage types.
@immutable
final class SpeedTestResult {
  /// Creates a result from measured values.
  const new({
    required this.timestamp,
    required this.downloadBps,
    required this.uploadBps,
    required this.latencyMs,
    required this.jitterMs,
    this.profile = SpeedTestProfile.balanced,
    this.server,
  });

  /// Builds a result from a completed [progress] update.
  // ignore: unnecessary_type_name_in_constructor
  factory SpeedTestResult.fromProgress(
    SpeedTestProgress progress, {
    required SpeedTestProfile profile,
    DateTime? timestamp,
  }) {
    assert(progress.isComplete, 'Only a completed run can become a result.');
    return SpeedTestResult(
      timestamp: timestamp ?? DateTime.now(),
      downloadBps: progress.downloadBps ?? 0,
      uploadBps: progress.uploadBps ?? 0,
      latencyMs: progress.latencyMs ?? 0,
      jitterMs: progress.jitterMs ?? 0,
      profile: profile,
      server: progress.server,
    );
  }

  /// Reads a persisted result.
  ///
  /// Throws a [FormatException] when a required field is missing or invalid so
  /// the data layer can skip just that entry.
  // ignore: unnecessary_type_name_in_constructor
  factory SpeedTestResult.fromJson(Map<Object?, Object?> json) {
    final rawTimestamp = json['timestamp'];
    final timestamp = rawTimestamp is String
        ? DateTime.tryParse(rawTimestamp)
        : null;
    final download = json['downloadBps'];
    final upload = json['uploadBps'];
    final latency = json['latencyMs'];
    final jitter = json['jitterMs'];
    if (timestamp == null ||
        download is! num ||
        upload is! num ||
        latency is! num ||
        jitter is! num) {
      throw const FormatException('Invalid speed test result.');
    }

    final rawServer = json['server'];
    return SpeedTestResult(
      timestamp: timestamp,
      downloadBps: download.toDouble(),
      uploadBps: upload.toDouble(),
      latencyMs: latency.toDouble(),
      jitterMs: jitter.toDouble(),
      profile: SpeedTestProfile.fromName(json['profile']),
      server: rawServer is Map<Object?, Object?>
          ? NetworkInfo.fromJson(rawServer)
          : null,
    );
  }

  /// When the test finished.
  final DateTime timestamp;

  /// Average download throughput in bits per second.
  final double downloadBps;

  /// Average upload throughput in bits per second.
  final double uploadBps;

  /// Median round-trip time in milliseconds.
  final double latencyMs;

  /// Average variation between latency samples in milliseconds.
  final double jitterMs;

  /// The data volume used by the run.
  final SpeedTestProfile profile;

  /// The endpoint and network that carried the test.
  final NetworkInfo? server;

  /// The JSON representation persisted in the key/value store.
  Map<String, Object?> toJson() => <String, Object?>{
    'timestamp': timestamp.toIso8601String(),
    'downloadBps': downloadBps,
    'uploadBps': uploadBps,
    'latencyMs': latencyMs,
    'jitterMs': jitterMs,
    'profile': profile.name,
    'server': server?.toJson(),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SpeedTestResult &&
          other.timestamp == timestamp &&
          other.downloadBps == downloadBps &&
          other.uploadBps == uploadBps &&
          other.latencyMs == latencyMs &&
          other.jitterMs == jitterMs &&
          other.profile == profile &&
          other.server == server;

  @override
  int get hashCode => Object.hash(
    timestamp,
    downloadBps,
    uploadBps,
    latencyMs,
    jitterMs,
    profile,
    server,
  );

  @override
  String toString() =>
      'SpeedTestResult(down: $downloadBps, up: $uploadBps, '
      'ping: $latencyMs, jitter: $jitterMs)';
}
