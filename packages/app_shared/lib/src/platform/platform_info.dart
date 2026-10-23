import 'package:flutter/foundation.dart';

/// Read-only platform facts used to branch UI and service wiring.
abstract final class PlatformInfo {
  /// Whether the app runs on the web.
  static bool get isWeb => kIsWeb;

  /// The platform Flutter targets.
  static TargetPlatform get targetPlatform => defaultTargetPlatform;

  /// Whether the app runs on a desktop operating system.
  static bool get isDesktop {
    if (isWeb) {
      return false;
    }
    return switch (defaultTargetPlatform) {
      TargetPlatform.linux ||
      TargetPlatform.macOS ||
      TargetPlatform.windows => true,
      TargetPlatform.android ||
      TargetPlatform.fuchsia ||
      TargetPlatform.iOS => false,
    };
  }

  /// Whether the app runs on a mobile operating system.
  static bool get isMobile {
    if (isWeb) {
      return false;
    }
    return switch (defaultTargetPlatform) {
      TargetPlatform.android || TargetPlatform.iOS => true,
      TargetPlatform.fuchsia ||
      TargetPlatform.linux ||
      TargetPlatform.macOS ||
      TargetPlatform.windows => false,
    };
  }

  /// Whether the app runs on an Apple platform.
  static bool get isApple =>
      !isWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  /// A human-readable platform name for diagnostics.
  static String get label {
    if (isWeb) {
      return 'web';
    }
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'Android',
      TargetPlatform.fuchsia => 'Fuchsia',
      TargetPlatform.iOS => 'iOS',
      TargetPlatform.linux => 'Linux',
      TargetPlatform.macOS => 'macOS',
      TargetPlatform.windows => 'Windows',
    };
  }
}
