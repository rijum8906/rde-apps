import 'package:app_shared/app_shared.dart';
import 'package:app_theme/app_theme.dart';
import 'package:calculator/app.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

/// Boots the calculator on Linux.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the window manager
  await windowManager.ensureInitialized();

  // Wide enough for the navigation rail; narrow windows still get the
  // bottom navigation bar down to the minimum size.
  const windowOptions = WindowOptions(
    size: Size(480, 750),
    minimumSize: Size(420, 650),
    center: true,
    title: 'Calculator',
  );

  // Wait until the window is ready before showing it to avoid visual flickers
  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  ServiceLocator.instance.register<KeyValueStore>(PreferencesStore());

  // The org.rde.Theme service is optional: when the desktop runs it, the
  // calculator adopts the desktop's Material palette and light/dark scheme,
  // and theme changes made here are published back to every app. Without it
  // the app keeps its locally stored selection. The client lives for the
  // process.
  final theme = RdeThemeClient();

  runApp(
    CalculatorApp(
      store: ServiceLocator.instance.get<KeyValueStore>(),
      themeSource: theme,
      themeSink: theme,
    ),
  );
}
