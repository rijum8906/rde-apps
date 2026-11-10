/// The amount of data a speed test transfers.
///
/// Larger profiles take longer but produce a more stable result on fast
/// connections. The byte counts are what the remote endpoint is asked to send
/// or receive, split across [connections] parallel streams so one TCP
/// connection's congestion window cannot cap the reading.
enum SpeedTestProfile {
  /// A fast check that uses little data.
  quick(
    label: 'Quick',
    description: 'Low data use. Two streams, best for a fast check.',
    downloadBytes: 25000000,
    uploadBytes: 10000000,
    latencySamples: 5,
    connections: 2,
  ),

  /// The default balance between accuracy and data use.
  balanced(
    label: 'Balanced',
    description: 'Four parallel streams, accurate on most connections.',
    downloadBytes: 50000000,
    uploadBytes: 20000000,
    latencySamples: 8,
    connections: 4,
  ),

  /// A longer test with more samples for fast or unstable connections.
  thorough(
    label: 'Thorough',
    description: 'Six streams and more data, best for fast links.',
    downloadBytes: 150000000,
    uploadBytes: 50000000,
    latencySamples: 12,
    connections: 6,
  );

  new({
    required this.label,
    required this.description,
    required this.downloadBytes,
    required this.uploadBytes,
    required this.latencySamples,
    required this.connections,
  });

  /// A short name suitable for a chip or a segmented button.
  final String label;

  /// A one-line explanation of the trade-off.
  final String description;

  /// The number of bytes downloaded during the test.
  final int downloadBytes;

  /// The number of bytes uploaded during the test.
  final int uploadBytes;

  /// The number of latency samples taken after the warm-up round trip.
  final int latencySamples;

  /// The number of parallel streams used by download and upload.
  final int connections;

  /// The data volume in megabytes, rounded for display.
  double get downloadMegabytes => downloadBytes / 1000000;

  /// The data volume in megabytes, rounded for display.
  double get uploadMegabytes => uploadBytes / 1000000;

  /// The total data transferred by one test, in megabytes.
  double get totalMegabytes => downloadMegabytes + uploadMegabytes;

  /// Reads a profile from its persisted [name], defaulting to [balanced].
  static SpeedTestProfile fromName(Object? name) {
    for (final profile in values) {
      if (profile.name == name) {
        return profile;
      }
    }
    return balanced;
  }
}
