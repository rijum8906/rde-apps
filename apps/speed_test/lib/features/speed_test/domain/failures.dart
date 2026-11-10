/// Base class for every speed test failure.
///
/// Each concrete failure owns the message shown to the user, so the
/// presentation layer never has to switch on a runtime type.
sealed class SpeedTestFailure implements Exception {
  /// Creates a failure.
  const new();

  /// The user-facing explanation of what went wrong.
  String get message;
}

/// The endpoint could not be reached, or the connection dropped.
final class NetworkFailure extends SpeedTestFailure {
  /// Creates a network failure with optional technical [details].
  const new({this.details});

  /// Diagnostic detail for logs. Never shown to the user.
  final String? details;

  @override
  String get message =>
      'Could not reach the speed test server. Check your connection and try '
      'again.';
}

/// A request made no progress before the timeout.
final class SpeedTestTimeoutFailure extends SpeedTestFailure {
  /// Creates a timeout failure.
  const new();

  @override
  String get message => 'The test timed out. Try again on a stable connection.';
}

/// The remote endpoint answered with an unexpected status.
final class ServerFailure extends SpeedTestFailure {
  /// Creates a server failure with the received [statusCode].
  const new({this.statusCode});

  /// The HTTP status returned by the endpoint, when available.
  final int? statusCode;

  @override
  String get message =>
      'The speed test server rejected the request. Try again '
      'later.';
}

/// Another request could not be read or written.
final class StorageFailure extends SpeedTestFailure {
  /// Creates a storage failure.
  const new();

  @override
  String get message => 'Could not read or save results on this device.';
}
