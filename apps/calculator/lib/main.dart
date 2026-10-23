import 'package:app_shared/app_shared.dart';
import 'package:calculator/app.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

/// Boots the calculator on Linux.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the window manager
  await windowManager.ensureInitialized();

  const windowOptions = WindowOptions(
    size: Size(500, 700), // Set your initial width and height
    minimumSize: Size(400, 300),
    center: true, // Center the window on the screen
    title: 'Calculator',
  );

  // Wait until the window is ready before showing it to avoid visual flickers
  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  ServiceLocator.instance.register<KeyValueStore>(PreferencesStore());

  runApp(CalculatorApp(store: ServiceLocator.instance.get<KeyValueStore>()));
}
