import 'package:app_shared/app_shared.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:desktop_app/app.dart';
import 'package:flutter/material.dart';

/// Boots the Linux desktop host.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  ServiceLocator.instance
    ..register<KeyValueStore>(PreferencesStore())
    ..register<SecureStore>(FlutterSecureStore())
    ..register<NotificationService>(const NoopNotificationService())
    ..register<Logger>(createDebugLogger(name: 'desktop_app'));

  // Dynamic color is optional: Linux may expose a system accent, and the
  // design system falls back to its static seed when it does not.
  final dynamicColors = await AppDynamicColors.load();

  runApp(DesktopApp(dynamicColors: dynamicColors));
}
