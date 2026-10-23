import 'package:core/core.dart';
import 'package:flutter/foundation.dart';

/// Whether the app is running in a debug build.
bool get isDebugBuild => kDebugMode;

/// Logs [message] through [debugPrint] in debug builds only.
///
/// The [name] prefixes the line, which makes it easy to filter the console in
/// a monorepo with several apps.
void debugLog(String message, {String name = 'app'}) {
  if (!kDebugMode) {
    return;
  }
  debugPrint('[$name] $message');
}

/// Creates a [Logger] that forwards every record to [debugPrint].
///
/// Records are dropped in release builds, so callers can log freely without
/// shipping noisy production logs.
Logger createDebugLogger({String name = 'app'}) {
  return CallbackLogger((record) {
    if (!kDebugMode) {
      return;
    }
    debugPrint('[$name] $record');
  });
}
