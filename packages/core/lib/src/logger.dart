/// Severity of a log record.
enum LogLevel {
  /// Fine-grained diagnostic information.
  debug,

  /// Normal application lifecycle events.
  info,

  /// Recoverable problems worth attention.
  warning,

  /// Failures that prevent the current operation from completing.
  error,
}

/// An immutable log record emitted by a [Logger].
final class LogRecord {
  /// Creates a log record.
  const new({
    required this.level,
    required this.message,
    required this.timestamp,
    this.error,
    this.stackTrace,
  });

  /// The severity of the record.
  final LogLevel level;

  /// The human-readable message.
  final String message;

  /// When the record was created.
  final DateTime timestamp;

  /// The associated error, if any.
  final Object? error;

  /// The stack trace associated with [error], if any.
  final StackTrace? stackTrace;

  @override
  String toString() {
    final buffer = StringBuffer('[$level] $message');
    if (error != null) {
      buffer.write(' | error: $error');
    }
    return buffer.toString();
  }
}

/// A minimal logging abstraction so packages never depend on a concrete sink.
abstract interface class Logger {
  /// Emits a record with [level], [message], and optional [error] details.
  void log(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  });

  /// Creates a logger that appends every record to [records] (useful in tests).
  static Logger memory(List<LogRecord> records) => _MemoryLogger(records);

  /// A logger that discards every record.
  static const Logger noop = NoopLogger();
}

/// Convenience methods on top of [Logger.log].
extension LoggerX on Logger {
  /// Logs a [LogLevel.debug] record.
  void debug(String message, {Object? error, StackTrace? stackTrace}) =>
      log(LogLevel.debug, message, error: error, stackTrace: stackTrace);

  /// Logs a [LogLevel.info] record.
  void info(String message, {Object? error, StackTrace? stackTrace}) =>
      log(LogLevel.info, message, error: error, stackTrace: stackTrace);

  /// Logs a [LogLevel.warning] record.
  void warning(String message, {Object? error, StackTrace? stackTrace}) =>
      log(LogLevel.warning, message, error: error, stackTrace: stackTrace);

  /// Logs a [LogLevel.error] record.
  void error(String message, {Object? error, StackTrace? stackTrace}) =>
      log(LogLevel.error, message, error: error, stackTrace: stackTrace);
}

/// A [Logger] that forwards formatted records to a callback.
final class CallbackLogger implements Logger {
  /// Creates a logger that invokes [onRecord] for every record.
  const new(this.onRecord);

  /// The sink invoked for every record.
  final void Function(LogRecord record) onRecord;

  @override
  void log(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    onRecord(
      LogRecord(
        level: level,
        message: message,
        timestamp: DateTime.now(),
        error: error,
        stackTrace: stackTrace,
      ),
    );
  }
}

/// A [Logger] that silently drops every record.
final class NoopLogger implements Logger {
  /// Creates a no-op logger.
  const new();

  @override
  void log(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {}
}

final class _MemoryLogger implements Logger {
  new(this._records);

  final List<LogRecord> _records;

  @override
  void log(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    _records.add(
      LogRecord(
        level: level,
        message: message,
        timestamp: DateTime.now(),
        error: error,
        stackTrace: stackTrace,
      ),
    );
  }
}
